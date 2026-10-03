"""Synthetic evidence checks; these tests never connect to an Android device."""

import copy
import importlib.util
import json
import types
import unittest
from pathlib import Path
from unittest.mock import Mock


SPEC = importlib.util.spec_from_file_location(
    'measure_entry_startup', Path(__file__).resolve().parents[1] / 'measure_entry_startup.py',
)
measurement = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(measurement)


def frame(index, timestamp, build=1000, raster=2000, total=4000):
    return {
        'type': 'frame', 'index': index, 'frame_number': index + 1,
        'build_start_us': timestamp, 'build_us': build, 'raster_us': raster, 'total_us': total,
    }


def fixture():
    frames = [frame(index, timestamp) for index, timestamp in enumerate((50, 150, 200, 300, 400, 500, 501))]
    return {
        'frames': frames,
        'summary': {
            'type': 'summary', 'schema': 1, 'profile': True, 'diagnostic': True,
            'started_at_us': 100, 'frame_count': len(frames), 'flush_ms': 1200,
            'marks': [
                {'phase': phase, 'time_us': timestamp}
                for phase, timestamp in (
                    ('initializing', 100), ('playing_standard', 200),
                    ('settled', 300), ('reveal', 400), ('finished', 500),
                )
            ],
        },
    }


def records(probe):
    return [*probe['frames'], probe['summary']]


def log(records_to_write):
    return 'unrelated log line\n' + '\n'.join(
        'I/flutter: ' + measurement.PREFIX + json.dumps(record) for record in records_to_write
    )


class ProbeParsingTest(unittest.TestCase):
    def test_waits_for_summary_then_parses_complete_probe(self):
        probe = fixture()
        self.assertIsNone(measurement.parse_records(log(probe['frames'])))
        self.assertEqual(measurement.parse_records(log(records(probe))), probe)

    def test_rejects_missing_duplicate_or_trailing_frame(self):
        probe = fixture()
        for invalid in (
            [*probe['frames'][1:], probe['summary']],
            [probe['frames'][0], *probe['frames'][:-1], probe['summary']],
            [probe['summary'], *probe['frames']],
        ):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                measurement.parse_records(log(invalid))

    def test_rejects_wrong_mode_bypassed_motion_and_unordered_marks(self):
        for mutation in ('profile', 'diagnostic', 'schema', 'playing', 'finish', 'unordered'):
            probe = fixture()
            summary = probe['summary']
            if mutation in ('profile', 'diagnostic'):
                summary[mutation] = False
            elif mutation == 'schema':
                summary['schema'] = 2
            elif mutation == 'playing':
                summary['marks'][1]['phase'] = 'disabled'
            elif mutation == 'finish':
                summary['marks'].pop()
            else:
                summary['marks'][2]['time_us'] = 50
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                measurement.parse_records(log(records(probe)))

    def test_rejects_empty_probe_negative_duration_and_multiple_summaries(self):
        probe = fixture()
        empty = copy.deepcopy(probe)
        empty['frames'] = []
        empty['summary']['frame_count'] = 0
        negative = copy.deepcopy(probe)
        negative['frames'][0]['raster_us'] = -1
        for invalid in (records(empty), records(negative), [*records(probe), probe['summary']]):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                measurement.parse_records(log(invalid))


class FrameSummaryTest(unittest.TestCase):
    def test_phase_boundaries_include_first_frame_and_exclude_post_finish(self):
        phases = measurement.phase_frames(fixture())
        expected = {
            'initializing': [0, 1], 'playing_standard': [2], 'settled': [3],
            'reveal': [4, 5], 'startup': [0, 1, 2, 3, 4, 5],
            'visual': [2, 3, 4, 5], 'post_finish': [6],
        }
        self.assertEqual({key: [value['index'] for value in values] for key, values in phases.items()}, expected)

    def test_percentiles_and_strict_budget_treat_build_and_raster_separately(self):
        frames = [
            frame(0, 0, 16700, 16701, 20000),
            frame(1, 1, 20000, 20000, 30000),
            frame(2, 2, 1000, 1000, 2000),
        ]
        summary = measurement.summarize_frames(frames, 16.7)
        self.assertEqual(summary['build']['p50_ms'], 16.7)
        self.assertEqual(summary['build']['p95_ms'], 20)
        self.assertEqual(summary['build']['max_ms'], 20)
        self.assertEqual(summary['build']['over_budget_count'], 1)
        self.assertEqual(summary['raster']['over_budget_count'], 2)
        self.assertEqual(summary['build_or_raster_over_budget_count'], 2)

    def test_aggregate_retains_every_run_and_nulls_for_empty_phase(self):
        report = measurement.aggregate([fixture(), fixture()], 16.7)
        self.assertEqual(report['runs'], 2)
        self.assertEqual(len(report['per_run']), 2)
        self.assertEqual(report['phases']['startup']['frame_count'], 12)
        self.assertEqual(report['phases']['visual']['frame_count'], 8)
        self.assertIsNone(measurement.summarize_frames([], 16.7)['build']['max_ms'])


class InstalledApkTest(unittest.TestCase):
    def test_accepts_only_matching_installed_universal_apk(self):
        device = measurement.Device(types.SimpleNamespace(user=10, package=measurement.PACKAGE))
        sha256 = 'b' * 64
        device.run = Mock(side_effect=['package:/data/app/example/base.apk', sha256 + '  /data/app/example/base.apk'])
        self.assertEqual(device.verify_installed_apk(sha256), {'path': '/data/app/example/base.apk', 'sha256': sha256})
        self.assertEqual(device.run.call_args_list[0].args, ('shell', 'pm', 'path', '--user', '10', measurement.PACKAGE))

    def test_rejects_mismatch_missing_or_split_apk(self):
        for output in (
            ['',],
            ['package:/base.apk\npackage:/split.apk'],
            ['package:/base.apk', 'a' * 64 + '  /base.apk'],
        ):
            device = measurement.Device(types.SimpleNamespace(user=10, package=measurement.PACKAGE))
            device.run = Mock(side_effect=output)
            with self.subTest(output=output), self.assertRaises(RuntimeError):
                device.verify_installed_apk('b' * 64)


if __name__ == '__main__':
    unittest.main()

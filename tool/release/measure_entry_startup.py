"""Collect opt-in Profile FrameTiming logs from real process cold starts.

Build with --profile --dart-define=HOOPTRACE_ENTRY_PROFILE=true, then install
that APK on the synthetic Android user before running this tool. This tool
never installs, uninstalls, clears app data, changes settings, or records video.
Its only device mutations are force-stop and explicit activity launch.
"""

import argparse
import datetime
import hashlib
import json
import math
import pathlib
import shlex
import subprocess
import time


PREFIX = 'HOOPTRACE_ENTRY_PROFILE_JSON '
PACKAGE = 'io.github.x1a0y4ngren.hooptrace'


def parse_records(log):
    """Read one complete probe, rejecting lost/truncated frame records."""
    records = []
    for line in log.splitlines():
        if PREFIX not in line:
            continue
        records.append(json.loads(line.split(PREFIX, 1)[1]))
    summaries = [record for record in records if record.get('type') == 'summary']
    if not summaries:
        return None
    if len(summaries) != 1:
        raise ValueError('Expected exactly one completed probe in the process.')
    if records[-1].get('type') != 'summary':
        raise ValueError('Completion summary must follow every frame record.')
    summary = summaries[0]
    if summary.get('schema') != 1 or not summary.get('profile') or not summary.get('diagnostic'):
        raise ValueError('Expected a diagnostic Profile probe with schema 1.')
    frames = [record for record in records if record.get('type') == 'frame']
    if len(frames) != summary['frame_count']:
        raise ValueError('Incomplete frame log; refusing partial performance evidence.')
    if [frame['index'] for frame in frames] != list(range(len(frames))):
        raise ValueError('Missing, duplicated, or unordered frame records.')
    marks = summary['marks']
    if not marks or marks[-1]['phase'] != 'finished':
        raise ValueError('Probe did not finish its visual sequence.')
    if not any(mark['phase'].startswith('playing_') for mark in marks):
        raise ValueError('Probe has no playing phase; startup animation was bypassed.')
    if any(left['time_us'] > right['time_us'] for left, right in zip(marks, marks[1:])):
        raise ValueError('Probe phase timestamps are unordered.')
    if not frames:
        raise ValueError('Probe contains no FrameTiming samples.')
    for frame in frames:
        for metric in ('build_us', 'raster_us', 'total_us'):
            if frame[metric] < 0:
                raise ValueError('Negative frame duration.')
    return {'summary': summary, 'frames': frames}


def percentile(values, fraction):
    """Nearest-rank percentile, recorded in the aggregate methodology."""
    return sorted(values)[max(0, math.ceil(len(values) * fraction) - 1)]


def summarize_frames(frames, budget_ms):
    result = {'frame_count': len(frames)}
    for metric in ('build', 'raster', 'total'):
        values = [frame[metric + '_us'] / 1000 for frame in frames]
        result[metric] = {
            'p50_ms': percentile(values, .50) if values else None,
            'p95_ms': percentile(values, .95) if values else None,
            'max_ms': max(values) if values else None,
            'over_budget_count': sum(value > budget_ms for value in values),
        }
    result['build_or_raster_over_budget_count'] = sum(
        max(frame['build_us'], frame['raster_us']) > budget_ms * 1000
        for frame in frames
    )
    return result


def phase_frames(probe):
    marks = probe['summary']['marks']
    finish_us = marks[-1]['time_us']
    result = {'initializing': [], 'visual': [], 'startup': [], 'post_finish': []}
    for mark in marks[:-1]:
        result.setdefault(mark['phase'], [])
    playing = next(mark['time_us'] for mark in marks if mark['phase'].startswith('playing_'))
    for frame in probe['frames']:
        timestamp = frame['build_start_us']
        if timestamp > finish_us:
            result['post_finish'].append(frame)
            continue
        result['startup'].append(frame)
        if timestamp >= playing:
            result['visual'].append(frame)
        phase = 'initializing'
        for mark in marks[:-1]:
            if mark['time_us'] <= timestamp:
                phase = mark['phase']
        result[phase].append(frame)
    return result


def aggregate(probes, budget_ms):
    grouped = {}
    runs = []
    for probe in probes:
        phases = phase_frames(probe)
        runs.append({name: summarize_frames(frames, budget_ms) for name, frames in phases.items()})
        for phase, frames in phases.items():
            grouped.setdefault(phase, []).extend(frames)
    return {
        'runs': len(probes),
        'motion_modes': {
            mode: sum(any(mark['phase'] == 'playing_' + mode
                          for mark in probe['summary']['marks']) for probe in probes)
            for mode in ('standard', 'reduced')
        },
        'budget_ms': budget_ms,
        'percentile_method': 'nearest rank over individual frames, no warmup samples discarded',
        'phase_method': 'FrameTiming build_start_us against Timeline.now phase marks; pre-gate first frame is initializing',
        'visual_method': 'first playing mark through finished, including settle/wait/reveal',
        'total_note': 'total includes pipeline latency; build and raster separately determine work-budget overruns',
        'phases': {name: summarize_frames(frames, budget_ms) for name, frames in grouped.items()},
        'per_run': runs,
    }


class Device:
    def __init__(self, args):
        self.args = args

    def run(self, *arguments, timeout=15):
        result = subprocess.run(
            [self.args.adb, '-s', self.args.serial, *arguments],
            check=True, capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=timeout,
        )
        return result.stdout.strip()

    def processes(self):
        rows = self.run('shell', 'ps', '-A', '-o', 'USER,PID,NAME').splitlines()
        return [int(parts[1]) for row in rows if len(parts := row.split()) == 3
                and parts[0].startswith(f'u{self.args.user}_') and parts[2] == self.args.package]

    def validate(self):
        current_user = int(self.run('shell', 'am', 'get-current-user'))
        users = self.run('shell', 'pm', 'list', 'users')
        if self.args.user != 10 or current_user != 10 or 'UserInfo{10:HoopTraceV2_Synthetic_' not in users:
            raise RuntimeError('Requires the existing synthetic user 10 in the foreground; no users/settings are changed.')
        api = self.run('shell', 'getprop', 'ro.build.version.sdk')
        if api != '36':
            raise RuntimeError(f'Expected API 36, found {api}.')
        power = self.run('shell', 'dumpsys', 'power')
        if 'mWakefulness=Awake' not in power:
            raise RuntimeError('Display is not awake. Wake/unlock the test device before measurement.')
        return {
            'serial': self.args.serial, 'android_user': current_user, 'api': int(api),
            'abi': self.run('shell', 'getprop', 'ro.product.cpu.abi'),
            'size': self.run('shell', 'wm', 'size'), 'density': self.run('shell', 'wm', 'density'),
            'model': self.run('shell', 'getprop', 'ro.product.model'),
            'scope': 'emulator measurement; not representative physical-device acceptance',
        }

    def verify_installed_apk(self, expected_sha256):
        paths = self.run('shell', 'pm', 'path', '--user', str(self.args.user), self.args.package).splitlines()
        if len(paths) != 1 or not paths[0].startswith('package:/'):
            raise RuntimeError('Expected one installed universal APK; split or missing APK is unsupported.')
        installed_path = paths[0].removeprefix('package:')
        actual_sha256 = self.run('shell', 'sha256sum', shlex.quote(installed_path)).split()[0].lower()
        if actual_sha256 != expected_sha256.lower():
            raise RuntimeError('Installed APK SHA-256 differs from --apk; refusing mismatched provenance.')
        return {'path': installed_path, 'sha256': actual_sha256}

    def cold_start(self, index):
        before_pids = self.processes()
        self.run('shell', 'am', 'force-stop', '--user', str(self.args.user), self.args.package)
        if self.processes():
            raise RuntimeError('App process survived force-stop; refusing a warm-start sample.')
        log_start = self.run('shell', 'date', "'+%m-%d %H:%M:%S.000'")
        deadline = time.monotonic() + self.args.timeout
        launch = self.run('shell', 'am', 'start', '-W', '--user', str(self.args.user), '-n',
                          self.args.package + '/' + self.args.activity, timeout=self.args.timeout)
        if 'Status: ok' not in launch:
            raise RuntimeError(f'Activity launch failed: {launch}')
        window = self.run('shell', 'dumpsys', 'window')
        focus = next((line.strip() for line in window.splitlines()
                      if 'mCurrentFocus=' in line), '')
        if self.args.package not in focus:
            raise RuntimeError(f'App is not visible in the foreground: {focus}')
        process_ids = self.processes()
        if len(process_ids) != 1:
            raise RuntimeError(f'Expected one new app process, found {process_ids}.')
        process_id = process_ids[0]
        log = ''
        while time.monotonic() < deadline:
            log = self.run('logcat', '-d', '-v', 'raw', '--pid', str(process_id), '-T', log_start)
            probe = parse_records(log)
            if probe:
                probe['launch'] = {
                    'run': index, 'previous_pids': before_pids, 'pid': process_id,
                    'force_stop_verified': True, 'am_start': launch,
                    'focused_window': focus,
                    'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
                }
                return probe, '\n'.join(line for line in log.splitlines() if PREFIX in line) + '\n'
            if self.processes() != [process_id]:
                raise RuntimeError('App process exited or changed before the probe finished.')
            time.sleep(.2)  # Bounded condition polling, not a fixed startup delay.
        raise TimeoutError(f'No complete Profile probe within {self.args.timeout}s (PID {process_id}).')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--adb', default='adb')
    parser.add_argument('--serial', default='emulator-5554')
    parser.add_argument('--user', type=int, default=10)
    parser.add_argument('--package', default=PACKAGE)
    parser.add_argument('--activity', default='.MainActivity')
    parser.add_argument('--runs', type=int, default=10)
    parser.add_argument('--timeout', type=float, default=30)
    parser.add_argument('--budget-ms', type=float, default=16.7)
    parser.add_argument('--output', type=pathlib.Path, required=True)
    parser.add_argument('--apk', type=pathlib.Path, required=True, help='Installed Profile APK, fingerprinted only; never installed by this tool.')
    parser.add_argument('--source-commit', required=True)
    args = parser.parse_args()
    if args.runs < 1 or args.timeout <= 0 or args.budget_ms <= 0:
        parser.error('runs, timeout, and budget must be positive')
    if args.output.exists() and any(args.output.iterdir()):
        parser.error('output directory must be new or empty; existing evidence is never overwritten')
    with args.apk.open('rb') as apk_file:
        apk_sha256 = hashlib.file_digest(apk_file, 'sha256').hexdigest()
    device = Device(args)
    environment = device.validate()
    installed_apk = device.verify_installed_apk(apk_sha256)
    args.output.mkdir(parents=True, exist_ok=True)
    provenance = {
        'source_commit': args.source_commit, 'profile_apk': str(args.apk.resolve()),
        'profile_apk_sha256': apk_sha256, 'device': environment,
        'verified_installed_apk': installed_apk,
        'recording_during_measurement': False,
        'cold_start_definition': 'user-scoped force-stop, verified absence of process, explicit activity launch; app data retained',
    }
    (args.output / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n', encoding='utf-8')
    probes = []
    for index in range(1, args.runs + 1):
        probe, log = device.cold_start(index)
        probes.append(probe)
        (args.output / f'run-{index:02}.json').write_text(json.dumps(probe, indent=2) + '\n', encoding='utf-8')
        (args.output / f'run-{index:02}.log').write_text(log, encoding='utf-8')
        print(f'Run {index}/{args.runs}: PID {probe["launch"]["pid"]}, {len(probe["frames"])} frames', flush=True)
    device.verify_installed_apk(apk_sha256)
    report = aggregate(probes, args.budget_ms)
    report['provenance'] = provenance
    (args.output / 'aggregate.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(report['phases'], indent=2))


if __name__ == '__main__':
    main()

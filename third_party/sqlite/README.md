# SQLite amalgamation

This directory contains the SQLite 3.53.4 amalgamation from the official
SQLite 2026 source archive. `package:sqlite3` is configured in the root
`pubspec.yaml` to compile `sqlite3.c` from this checked-in source instead of
downloading a prebuilt GitHub release asset.

Source archive: <https://www.sqlite.org/2026/sqlite-amalgamation-3530400.zip>
`sqlite3.c` SHA-256: `b1dd5d74ec7f29055a6684fa06fb3c2f6821c87dd38f9a458dfd2e8a1db28189`
`sqlite3.h` SHA-256: `919e7f2e8ed1d8f56ac17b412b8971c76aa5d1a879752cc6058f75e7d5910e1d`

The archive is used under SQLite's public-domain dedication. See
`LICENSE.sqlite` for the upstream notice. Keep `sqlite3.c` and `sqlite3.h`
from the same upstream archive when updating the pinned SQLite version, then
record the new archive URL and SHA-256 in the release reproducibility notes.

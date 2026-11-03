#!/usr/bin/env python3
"""Add Android INTERNET permission to SplitLui's release/main manifest.

This repo bootstraps Android with `flutter create` on each developer's
machine, so we patch (rather than overwrite) the generated native manifest.
Requires only Python 3 standard library.
"""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
PERMISSION = "android.permission.INTERNET"

if not MANIFEST.is_file():
    print(
        "Missing android/app/src/main/AndroidManifest.xml. "
        "First run: flutter create --project-name splitlui "
        "--org dev.cloudfullstack .",
        file=sys.stderr,
    )
    sys.exit(1)

source = MANIFEST.read_text(encoding="utf-8")
pattern = re.compile(
    r"""<uses-permission\b[^>]*\bandroid:name\s*=\s*['"]android\.permission\.INTERNET['"]""",
    re.DOTALL,
)
if pattern.search(source):
    print(f"Already configured: {MANIFEST.relative_to(ROOT)}")
    sys.exit(0)

opening_tag = re.search(r"<manifest\b[^>]*>", source, re.DOTALL)
if opening_tag is None:
    print("AndroidManifest.xml has no <manifest> opening tag.", file=sys.stderr)
    sys.exit(1)

insert_at = opening_tag.end()
updated = (
    source[:insert_at]
    + '\n    <uses-permission android:name="android.permission.INTERNET" />'
    + source[insert_at:]
)
# Preserve all existing activity, package, icon and Flutter configuration.
MANIFEST.write_text(updated, encoding="utf-8")
print(f"Added INTERNET permission: {MANIFEST.relative_to(ROOT)}")

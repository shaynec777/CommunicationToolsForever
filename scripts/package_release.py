"""Build and verify an addon-only release ZIP; run from any directory."""
import hashlib
import json
import re
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
addon = root / "CommunicationToolsForever"
toc = (addon / "CommunicationToolsForever.toc").read_text(encoding="utf-8")
version = re.search(r"^## Version: (.+)$", toc, re.M)[1]
assert f'FC.version = "{version}"' in (addon / "Core.lua").read_text(encoding="utf-8")
entries = [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith("#")]
assert all((addon / entry).is_file() for entry in entries)
for name in ("README.txt", "LICENSE", "CHANGELOG.md"):
    assert (addon / name).is_file()
files = [p for p in addon.rglob("*") if p.is_file() and p.name not in {"RadioLogo.png", "LogoPrompt.txt"}]
out = root / "releases"
out.mkdir(exist_ok=True)
archive = out / f"CommunicationToolsForever-{version}.zip"
with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
    for path in sorted(files):
        bundle.write(path, path.relative_to(root).as_posix())
with zipfile.ZipFile(archive) as bundle:
    assert bundle.testzip() is None
    assert {name.split('/')[0] for name in bundle.namelist()} == {addon.name}
    assert len(bundle.namelist()) == len(files)
    for path in files:
        assert bundle.read(path.relative_to(root).as_posix()) == path.read_bytes()
manifest = {
    "version": version, "release_type": "beta", "game_version": "1.60.1", "interface": 16001,
    "archive": archive.name, "size": archive.stat().st_size,
    "sha256": hashlib.sha256(archive.read_bytes()).hexdigest(), "files": len(files),
    "checks": ["runtime/TOC versions", "TOC references", "ZIP CRC", "addon-only root", "source/archive equality"],
}
(out / f"CommunicationToolsForever-{version}-package.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(json.dumps(manifest, indent=2))

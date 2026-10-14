"""Package a standalone source project and Git history. No engine/cache/temp files."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'outputs'
OUT.mkdir(exist_ok=True)
git = ['git', '-c', f'safe.directory={ROOT.as_posix()}', '-C', str(ROOT)]
revision = subprocess.check_output(git + ['rev-parse', 'HEAD'], text=True).strip()
bundle = OUT / '31days-v0.1.bundle'
subprocess.run(git + ['bundle', 'create', str(bundle), '--all'], check=True)
subprocess.run(git + ['bundle', 'verify', str(bundle)], check=True)
archive = OUT / '31days-v0.1-graybox.zip'
manifest = {}
with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as zipped:
    paths = [p for p in (ROOT / 'game').rglob('*')
             if p.is_file() and '.godot' not in p.parts]
    paths += [ROOT / '.gitattributes', ROOT / '.gitignore', ROOT / 'scripts/verify_game.py']
    for path in sorted(paths):
        name = path.relative_to(ROOT).as_posix()
        zipped.write(path, name)
        manifest[name] = hashlib.sha256(path.read_bytes()).hexdigest()
    zipped.write(bundle, bundle.name)
    if (OUT / 'engine_validation.txt').is_file():
        zipped.write(OUT / 'engine_validation.txt', 'verification/engine_validation.txt')
    zipped.writestr('verification/manifest.json', json.dumps({'commit': revision, 'sha256': manifest}, indent=2))
with zipfile.ZipFile(archive) as zipped:
    assert zipped.testzip() is None
    assert 'game/project.godot' in zipped.namelist()
    assert 'game/tests/test_player.gd' in zipped.namelist()
    assert not any('/.godot/' in name for name in zipped.namelist())
    for name, digest in manifest.items():
        assert hashlib.sha256(zipped.read(name)).hexdigest() == digest
shutil.copyfile(ROOT / 'game/README.md', OUT / '运行说明与实现清单.md')
(OUT / 'delivery_manifest.json').write_text(json.dumps({
    'commit': revision,
    'archive': archive.name,
    'archive_sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
    'files': len(manifest),
    'engine': '4.7.2.stable.official.ed1daf0bf',
}, indent=2), encoding='utf-8')
print(f'Archive verified: {archive}; commit: {revision}; files: {len(manifest)}')

from pathlib import Path
import hashlib,json,re,zipfile
root=Path(__file__).resolve().parent
addon=root/'CommunicationToolsClassic'
version=re.search(r'^## Version: (.+)$',(addon/'CommunicationToolsClassic.toc').read_text(),re.M)[1]
assert f'FC.version = "{version}"' in (addon/'Core.lua').read_text()
for line in (addon/'CommunicationToolsClassic.toc').read_text().splitlines():
 if line and not line.startswith('#'): assert (addon/line).is_file(),line
files=sorted(p for p in addon.rglob('*') if p.is_file())
out=root.parent/'releases'/f'CommunicationToolsClassic-{version}.zip'
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as bundle:
 for p in files: bundle.write(p,p.relative_to(root).as_posix())
with zipfile.ZipFile(out) as bundle:
 assert bundle.testzip() is None
 assert all(n.startswith('CommunicationToolsClassic/') for n in bundle.namelist())
 for p in files: assert bundle.read(p.relative_to(root).as_posix()) == p.read_bytes()
manifest={'version':version,'interface':11509,'game_version':'1.15.9','files':len(files),'archive':out.name,'sha256':hashlib.sha256(out.read_bytes()).hexdigest()}
out.with_suffix('.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(manifest))

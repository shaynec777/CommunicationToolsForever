"""Publish this project's source and beta ZIP using the existing GitHub credential."""
import argparse
import hashlib
import json
import os
import subprocess
import urllib.error
import urllib.request
from pathlib import Path

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument("action", choices=("inspect", "publish"))
args = parser.parse_args()
os.environ.pop("SSLKEYLOGFILE", None)
env = dict(os.environ, GIT_TERMINAL_PROMPT="0", GCM_INTERACTIVE="Never")
credential = subprocess.run(["git", "credential", "fill"], input="protocol=https\nhost=github.com\n\n",
                            text=True, capture_output=True, env=env)
if credential.returncode:
    raise SystemExit("The existing GitHub credential is unavailable; sign-in is required.")
fields = dict(line.split("=", 1) for line in credential.stdout.splitlines() if "=" in line)
token = fields.get("password")
if not token:
    raise SystemExit("No GitHub token was returned by the credential manager.")

def call(path, payload=None, method=None, content="application/json"):
    url = path if path.startswith("https://") else "https://api.github.com" + path
    data = json.dumps(payload).encode() if isinstance(payload, dict) else payload
    request = urllib.request.Request(url, data=data, method=method,
        headers={"Authorization": "Bearer " + token, "Accept": "application/vnd.github+json",
                 "Content-Type": content, "User-Agent": "CommunicationToolsForever-release"})
    with urllib.request.urlopen(request, timeout=60) as response:
        return json.load(response)

user = call("/user")
owner = user["login"]
if owner != "shaynec777":
    raise SystemExit("The authenticated account differs from HunterTools' owner; select the intended account first.")
name = "CommunicationToolsForever"
api = f"/repos/{owner}/{name}"
try:
    repo = call(api)
except urllib.error.HTTPError as error:
    if error.code != 404:
        raise
    repo = None
if args.action == "inspect":
    print(json.dumps({"account": owner, "repository_exists": repo is not None,
                      "huntertools_license": call(f"/repos/{owner}/HunterTools").get("license", {})}))
    raise SystemExit()
if not repo:
    repo = call("/user/repos", {"name": name, "description": "Communication tools for World of Warcraft: Forever — buffs, ignore, DND and name alerts.",
                               "private": False, "auto_init": False, "has_issues": True})
if repo.get("private"):
    raise SystemExit("An existing private repository was found; visibility has not been changed.")

def git(*arguments):
    return subprocess.check_output(["git", "-C", str(root), *arguments], text=True, env=env).strip()

git("config", "user.name", owner)
git("config", "user.email", f'{user["id"]}+{owner}@users.noreply.github.com')
try:
    existing_remote = git("remote", "get-url", "origin")
except subprocess.CalledProcessError:
    git("remote", "add", "origin", repo["clone_url"])
else:
    if existing_remote != repo["clone_url"]:
        raise SystemExit("Existing origin differs from the intended project; no push performed.")
git("add", "--", "CommunicationToolsForever", "tests", "scripts", ".gitignore", "README.md", "USER-GUIDE.md", "DESCRIPTION.md", "LICENSE", "CHANGELOG.md", "RELEASE-NOTES.md")
if subprocess.run(["git", "-C", str(root), "diff", "--cached", "--quiet"], env=env).returncode:
    git("commit", "-m", "Release CommunicationTools Forever 0.10.1 beta")
commit = git("rev-parse", "HEAD")
git("push", "-u", "origin", "HEAD:main")
version = "0.10.1"
try:
    release = call(api + f"/releases/tags/v{version}")
except urllib.error.HTTPError as error:
    if error.code != 404:
        raise
    release = call(api + "/releases", {"tag_name": "v" + version, "target_commitish": commit,
        "name": "CommunicationTools Forever " + version + " beta", "draft": False, "prerelease": True,
        "body": (root / "RELEASE-NOTES.md").read_text(encoding="utf-8")})
archive = root / "releases" / f"CommunicationToolsForever-{version}.zip"
digest = "sha256:" + hashlib.sha256(archive.read_bytes()).hexdigest()
assets = call(api + f'/releases/{release["id"]}/assets')
asset = next((asset for asset in assets if asset["name"] == archive.name), None)
if asset is None:
    asset = call(release["upload_url"].split("{")[0] + "?name=" + archive.name, archive.read_bytes(), content="application/zip")
assert asset.get("digest") == digest, "Uploaded ZIP digest differs"
result = {"repository": repo["html_url"], "release": release["html_url"], "commit": commit,
          "asset": asset["browser_download_url"], "digest_verified": True}
(root / "releases" / f"CommunicationToolsForever-{version}-github.json").write_text(json.dumps(result, indent=2) + "\n")
print(json.dumps(result, indent=2))

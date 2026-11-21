"""Build Plex photo albums from the rules in collections/family-photo-albums.yml."""

import argparse
from collections import defaultdict
from datetime import date
import fcntl
import hashlib
import os
from pathlib import Path, PurePosixPath
import re
import tempfile
from urllib.parse import urlencode
from urllib.request import Request, urlopen
from xml.etree import ElementTree as ET

import yaml


DEFAULT_RULES = Path(__file__).resolve().parents[1] / "collections/family-photo-albums.yml"


def words(value):
    value = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1 \2", value)
    value = re.sub(r"([a-z0-9])([A-Z])", r"\1 \2", value)
    return " ".join(re.findall(r"[a-z0-9]+", value.lower()))


def matches(rule, path, taken):
    folders = path.parts[:-1]
    segments = [words(re.sub(r"^\d{2}_", "", part)) for part in folders]
    stem = words(path.stem)
    names = [*segments, stem]
    if "exclude" in rule and any(rule["exclude"].search(s) for s in names):
        return False
    if any(rule["match"].search(s) for s in names):
        return True
    calendar = rule.get("calendar")
    if not calendar or not taken or taken[5:] != calendar["month_day"]:
        return False
    # A scan date in Undated or an unrelated event on a holiday is poor evidence.
    if not folders or folders[0] != taken[:4]:
        return False
    # July's parade needs a named folder. Halloween also accepts a bare year folder.
    context = segments[1:] or segments[:1]
    return all(calendar["folders"].fullmatch(s) for s in context)


class Plex:
    def __init__(self, url, token):
        self.url = url.rstrip("/")
        self.token = token

    def request(self, path, params=None, method="GET"):
        if not path.startswith("/") or path.startswith("//"):
            raise ValueError("Expected a path on the configured Plex server")
        if params:
            path += "?" + urlencode(params)
        req = Request(self.url + path, method=method, headers={"X-Plex-Token": self.token})
        with urlopen(req, timeout=90) as response:
            data = response.read()
        return ET.fromstring(data) if data.strip() else None

    def pages(self, path, **params):
        offset = 0
        while True:
            page = self.request(path, {**params, "X-Plex-Container-Start": offset,
                                       "X-Plex-Container-Size": 500})
            if int(page.get("offset", offset)) != offset:
                raise RuntimeError("Plex returned an unexpected page offset")
            yield from page
            offset += len(page)
            if offset >= int(page.get("totalSize", offset)):
                return
            if not len(page):
                raise RuntimeError("Plex returned an incomplete list")


def inventory(plex, section):
    roots = [PurePosixPath(n.attrib["path"]) for n in section.findall("Location")]
    pending = [f"/library/sections/{section.attrib['key']}/all"]
    visited = set()
    photos = {}
    while pending:
        key = pending.pop()
        if key in visited:
            continue
        visited.add(key)
        for item in plex.pages(key):
            if item.tag == "Directory" and item.get("key", "").startswith("/library/metadata/"):
                pending.append(item.attrib["key"])
            if item.tag != "Photo" or item.get("type") != "photo":
                continue
            part = item.find("Media/Part")
            if part is None or not part.get("file"):
                raise RuntimeError("Plex omitted a photo's file path")
            full = PurePosixPath(part.attrib["file"])
            root = next((r for r in roots if full.is_relative_to(r)), None)
            if root is None:
                raise ValueError("Plex returned a photo outside this library's folders")
            photos[item.attrib["ratingKey"]] = (full.relative_to(root), item.get("originallyAvailableAt", ""))
    return photos


def read_rules(config):
    for title, rule in config["albums"].items():
        for field in ("match", "exclude"):
            if field in rule:
                rule[field] = re.compile(rule[field])
        if "calendar" in rule:
            cal = rule["calendar"]
            date.fromisoformat("2000-" + cal["month_day"])
            cal["folders"] = re.compile(cal["folders"])
        if not title.strip() or "match" not in rule:
            raise ValueError(f"Invalid photo album definition: {title!r}")
    return config["albums"]


def membership(plex, album):
    return {n.attrib["ratingKey"] for n in plex.pages(album.attrib["key"])
            if n.tag == "Photo"}


def sync(plex, config, apply, only):
    rules = read_rules(config)
    if only:
        rules = {name: rules[name] for name in only}
    sections = [s for s in plex.pages("/library/sections")
                if s.get("type") == "photo" and s.get("title") == config["library"]]
    if len(sections) != 1:
        raise ValueError(f"Expected exactly one photo library named {config['library']}")
    photos = inventory(plex, sections[0])
    wanted = {name: [] for name in rules}
    for key, (path, taken) in sorted(photos.items(), key=lambda item: (
        item[1][1] or "9999", str(item[1][0]).casefold(), int(item[0])
    )):
        for name, rule in rules.items():
            if matches(rule, path, taken):
                wanted[name].append(key)

    existing = defaultdict(list)
    for album in plex.pages("/playlists", playlistType="photo"):
        existing[album.get("title", "").casefold()].append(album)
    identifier = plex.request("/identity").attrib["machineIdentifier"]
    prefix = f"server://{identifier}/com.plexapp.plugins.library/library/metadata/"
    plans = []
    for title, keys in wanted.items():
        same = existing[title.casefold()]
        if len(same) > 1 or any(a.get("smart") == "1" or a.get("readOnly") == "1" for a in same):
            raise ValueError(f"Ambiguous or read-only album: {title}")
        album = same[0] if same else None
        current = membership(plex, album) if album is not None else set()
        if current - photos.keys():
            raise ValueError(f"The existing album {title} contains photos outside the selected library")
        plans.append((title, album, keys, [k for k in keys if k not in current]))

    print(f"{config['library']}: {len(photos):,} pictures", flush=True)
    for title, album, keys, missing in plans:
        print(f"{title}: {len(keys):,} matching, {len(missing):,} to add", flush=True)
        if not apply or not missing:
            continue
        for start in range(0, len(missing), 100):
            uri = prefix + ",".join(missing[start:start + 100])
            if album is None:
                created = plex.request("/playlists", dict(type="photo", title=title, smart=0, uri=uri), "POST")
                album = created.find("Playlist")
                if album is None or album.get("playlistType") != "photo":
                    raise RuntimeError(f"Plex did not confirm creation of {title}")
            else:
                plex.request(album.attrib["key"], {"uri": uri}, "PUT")
        if not set(keys).issubset(membership(plex, album)):
            raise RuntimeError(f"Plex did not confirm all photos in {title}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--rules", type=Path, default=DEFAULT_RULES)
    parser.add_argument("--apply", action="store_true", help="Create albums and add missing photos")
    parser.add_argument("--only", action="append", metavar="TITLE", help="Select one album (repeatable)")
    args = parser.parse_args()
    config = yaml.safe_load(args.rules.read_text())
    plex = Plex(os.environ["KOMETA_SERVERURL"], os.environ["KOMETA_PLEXTOKEN"])
    lock_id = hashlib.sha256((plex.url + "/" + config["library"]).encode()).hexdigest()[:16]
    # Two simultaneous writers on the same host should never add the same pictures.
    lock_path = Path(tempfile.gettempdir()) / f"kometa-photo-albums-{os.getuid()}-{lock_id}.lock"
    with lock_path.open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        sync(plex, config, args.apply, args.only)


if __name__ == "__main__":
    main()

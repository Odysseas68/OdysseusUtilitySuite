"""Stage the approved OUS runtime files; never creates archives or invokes Git."""

import argparse
import hashlib
import json
from pathlib import Path, PureWindowsPath
import shutil
import stat
import sys
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parent.parent
ADDON = "OdysseusUtilitySuite"
TOC = ADDON + ".toc"
STAGING = ROOT / "release" / "staging"
ASSETS = ROOT / "Tools" / "production_assets.txt"


def check_tree(path):
    """Reject links and Windows junctions before reading or removing owned paths."""
    path.relative_to(ROOT)
    if ROOT.is_symlink():
        raise ValueError(f"Symlink root: {ROOT}")
    current = ROOT
    for name in path.relative_to(ROOT).parts:
        current = current / name
        if current.is_symlink() or (
            current.exists()
            and getattr(current.lstat(), "st_file_attributes", 0)
            & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)
        ):
            raise ValueError(f"Symlink or reparse point: {current}")
    if not path.resolve().is_relative_to(ROOT):
        raise ValueError(f"Path escapes repository: {path}")


def source_file(raw):
    """Require safe relative paths and exact on-disk capitalization."""
    name = raw.replace("\\", "/")
    parts = name.split("/")
    if not name or PureWindowsPath(name).drive or any(
        part in ("", ".", "..") or ":" in part for part in parts
    ):
        raise ValueError(f"Unsafe relative path: {raw!r}")
    path = ROOT.joinpath(*parts)
    check_tree(path)
    if not path.is_file():
        raise ValueError(f"Missing required file: {name}")
    current = ROOT
    for part in parts:
        if part not in {item.name for item in current.iterdir()}:
            raise ValueError(f"Path case mismatch: {name}")
        current = current / part
    return path


def code_path(name):
    """Limit TOC/XML expansion to production code locations and extensions."""
    path = source_file(name)
    rel = path.relative_to(ROOT)
    if path.suffix.lower() not in (".lua", ".xml") or not (
        len(rel.parts) == 1 or rel.parts[0] in ("Config2", "Libs")
    ):
        raise ValueError(f"Not approved production code: {name}")
    return path


def select_files():
    """Expand only TOC code, XML Script/Include references and approved media."""
    selected = {TOC}

    def visit(name):
        path = code_path(name)
        rel = path.relative_to(ROOT).as_posix()
        if rel in selected:
            return
        selected.add(rel)
        if path.suffix.lower() == ".xml":
            for element in ET.parse(path).iter():
                if element.tag.rsplit("}", 1)[-1] in ("Script", "Include"):
                    entry = element.get("file")
                    if entry:
                        # Resolve relative XML references without normalizing away '..'.
                        parent = path.parent.relative_to(ROOT).as_posix()
                        visit(entry if parent == "." else parent + "/" + entry)

    for line in source_file(TOC).read_text(encoding="utf-8-sig").splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            visit(line)
    check_tree(ASSETS)
    for line in ASSETS.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        path = source_file(line)
        rel = path.relative_to(ROOT)
        if rel.parent.as_posix() not in ("media/Textures", "media/icon") or path.suffix != ".tga":
            raise ValueError(f"Not approved production media: {line}")
        selected.add(rel.as_posix())
    required = {
        "media/Textures/CoinSpin.tga", "media/Textures/GoblinCounting.tga",
        "media/icon/OUS_icon_128.tga", "media/icon/OUS_banner.tga",
    }
    if not required <= selected:
        raise ValueError("Required production media absent from asset allowlist")
    return sorted(selected)


def remove_owned(path):
    """Remove only fixed staging outputs after checking their full local trees."""
    if path.parent != STAGING:
        raise ValueError(f"Not an owned staging output: {path}")
    check_tree(path)
    if path.is_dir():
        for child in path.rglob("*"):
            check_tree(child)
        shutil.rmtree(path)
    elif path.exists():
        path.unlink()


def stage():
    """Invalidate old results first; publish the manifest only after complete copying."""
    check_tree(STAGING)
    STAGING.mkdir(parents=True, exist_ok=True)
    destination = STAGING / ADDON
    work = STAGING / ".working"
    manifest = STAGING / "manifest.json"
    # No recursive deletion outside these three fixed staging-owned paths.
    for path in (manifest, destination, work):
        remove_owned(path)
    try:
        files = select_files()
        work.mkdir()
        records = []
        for name in files:
            data = source_file(name).read_bytes()
            target = work / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
            records.append({"path": name, "bytes": len(data),
                            "sha256": hashlib.sha256(data).hexdigest()})
        work.rename(destination)
        manifest.write_text(json.dumps({"addon": ADDON, "file_count": len(files),
                                        "files": records}, indent=2) + "\n", encoding="utf-8")
    except Exception:
        for path in (manifest, destination, work):
            remove_owned(path)
        raise
    print(f"Staged {len(files)} files in {destination}")
    print(f"Manifest: {manifest}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="Validate/list only; do not alter staging")
    args = parser.parse_args()
    try:
        if args.dry_run:
            files = select_files()
            print("\n".join(files))
            print(f"Dry run: {len(files)} files; staging unchanged.")
        else:
            stage()
    except (OSError, ValueError, ET.ParseError) as error:
        print(f"Staging failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

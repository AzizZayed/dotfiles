from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional


def panic(msg: str, code: int = 1) -> None:
    print(f"!! {msg}", file=sys.stderr)
    raise SystemExit(code)


def repo_dir() -> Path:
    return Path(__file__).resolve().parent


def symlink_target(symlink: Path) -> Path:
    return (symlink.parent / os.readlink(symlink)).resolve()


def pretty_home_path(path: Path) -> str:
    """Return path as a string, replacing the home prefix with ~ for readability."""
    try:
        return "~/" + str(path.relative_to(Path.home()))
    except ValueError:
        return str(path)


def move_to_trash(path: Path) -> None:
    """Move path to the OS trash/recycle bin without permanently deleting it."""
    if sys.platform == "darwin":
        trash_dir = Path.home() / ".Trash"
    elif sys.platform.startswith("linux"):
        trash_dir = Path.home() / ".local" / "share" / "Trash" / "files"
    elif sys.platform == "win32":
        trash_dir = (
            Path(os.environ.get("USERPROFILE", "C:\\Users\\Default"))
            / "AppData"
            / "Local"
            / "Temp"
            / "Trash"
        )
    else:
        panic(f"Unsupported platform for trash: {sys.platform}")

    trash_dir.mkdir(parents=True, exist_ok=True)
    dest = trash_dir / path.name
    counter = 1
    while dest.exists() or dest.is_symlink():
        dest = trash_dir / f"{path.stem}_{counter}{path.suffix}"
        counter += 1
    shutil.move(str(path), str(dest))


@dataclass(frozen=True)
class Link:
    """
    A declaration of a symlink to be created.

    src: path to the source file/dir (absolute).
    dst: path where the symlink will be created (absolute).
    """

    src: Path
    dst: Path

    @staticmethod
    def from_dict(d: dict, src_base: Path) -> Link:
        """Create a Link from a dict with 'src' and 'dst' keys."""
        src = Path(d["src"])  # Provided as absolute or relative to repo
        dst = Path(d["dst"])  # Provided as absolute always

        src = src if src.is_absolute() else (src_base / src)
        dst = dst.expanduser()  # Expand ~ in destination

        src = src.resolve()

        if not src.exists():
            panic(f"Source does not exist: {src}")

        return Link(src=src, dst=dst)

    def create(self):
        """
        Create the symlink at dst pointing to src.
        Panics if dst already exists (either as a file/dir or a symlink) to avoid overwriting anything.
        """
        if self.dst.exists() or self.dst.is_symlink():
            panic(f"Cannot create link, destination already exists: {self.dst}")
        self.dst.parent.mkdir(parents=True, exist_ok=True)
        os.symlink(self.src, self.dst)

    def exists(self) -> bool:
        """Check if the symlink at dst exists (non-dangling symlink) and points to src."""
        return self.dst.is_symlink() and symlink_target(self.dst) == self.src

    def is_dir(self) -> bool:
        return self.src.is_dir()

    def is_file(self) -> bool:
        return self.src.is_file()

    def remove(self):
        """Remove the symlink at dst if it exists."""
        if self.exists():
            self.dst.unlink()

    def matches(self, pattern: str) -> bool:
        """Return True if this link's src or dst path contains the given pattern."""
        return pattern in str(self.src) or pattern in str(self.dst)


@dataclass(frozen=True)
class Manifest:
    """A collection of symlink declarations with the context needed to apply them."""

    links: List[Link]

    @staticmethod
    def from_dict(d: dict, src_base: Path) -> Manifest:
        links = [Link.from_dict(item, src_base) for item in d["links"]]
        return Manifest(links=links)

    def _filtered(self, only: Optional[str]) -> List[Link]:
        if only is None:
            return self.links
        matched = [l for l in self.links if l.matches(only)]
        if not matched:
            panic(f"No links matched pattern: {only!r}")
        return matched

    def status(self, only: Optional[str] = None):
        for link in self._filtered(only):
            if link.exists():
                print(f"LINKED     {link.dst} -> {link.src}")
            elif link.dst.is_symlink():  # dst is symlink, but points to wrong target
                tgt = symlink_target(link.dst)
                pretty = pretty_home_path(tgt)
                print(f"WRONG LINK {link.dst} -> {pretty} (expected {link.src})")
            else:
                print(f"NOT LINKED {link.dst}")

    def install(self, force_install: bool, only: Optional[str] = None):
        """
        Create symlinks as declared in the manifest.
        force_install: if True, will remove existing symlinks at dst that don't point to src.
        """
        for link in self._filtered(only):
            if link.exists():
                print(f"SKIP       {link.dst} -> {link.src}")
            elif not link.dst.exists() and not link.dst.is_symlink():
                print(f"++ LINK    {link.dst} -> {link.src}")
                link.create()
            elif link.dst.is_symlink() and force_install:
                tgt = symlink_target(link.dst)
                print(f"!! RELINK  {link.dst} -> {tgt}, expected -> {link.src})")
                link.dst.unlink()
                link.create()
            elif link.dst.is_symlink():
                tgt = symlink_target(link.dst)
                print(f"!! SKIP    {link.dst} -> {tgt}, use --force to relink")
            else:
                print(
                    f"!! SKIP    {link.dst} exists and is not a symlink, use 'backup' or 'delete' first"
                )

    def remove(self, only: Optional[str] = None):
        """Remove symlinks that point into this repo."""
        for link in self._filtered(only):
            if link.exists():
                print(f"-- REMOVE  {link.dst}")
                link.remove()

    def backup(self, only: Optional[str] = None):
        """Copy files/dirs blocking symlink destinations to <dst>.bkp without deleting them."""
        for link in self._filtered(only):
            dst = link.dst
            if not dst.exists() and not dst.is_symlink():
                print(f"SKIP       {dst} (nothing there)")
                continue
            if link.exists():
                print(f"SKIP       {dst} (already linked correctly)")
                continue
            bkp = dst.parent / (dst.name + ".bkp")
            if bkp.exists():
                print(f"!! SKIP    {dst} -> backup already exists at {bkp}")
                continue
            if dst.is_dir() and not dst.is_symlink():
                shutil.copytree(dst, bkp)
            else:
                shutil.copy2(dst, bkp)
            print(f"~~ BACKUP  {dst} -> {bkp}")

    def delete(self, only: Optional[str] = None):
        """Move whatever is at each link's dst to trash so a symlink can be placed there."""
        for link in self._filtered(only):
            dst = link.dst
            if not dst.exists() and not dst.is_symlink():
                print(f"SKIP       {dst} (nothing there)")
                continue
            if link.exists():
                print(f"SKIP       {dst} (already linked correctly)")
                continue
            move_to_trash(dst)
            print(f"~~ TRASH   {dst}")


def cmd_add(links_file: Path, src: str, dst: str) -> None:
    """Add a new link entry to the dotfiles.json file."""
    data = json.loads(links_file.read_text())
    for entry in data["links"]:
        if entry["src"] == src and entry["dst"] == dst:
            panic(f"Entry already exists: {src!r} -> {dst!r}")
    data["links"].append({"src": src, "dst": dst})
    links_file.write_text(json.dumps(data, indent=2) + "\n")
    print(f"++ ADD     {src} -> {dst}")


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="dotfiles.py",
        description="Dotfiles manager: create symlinks from a repo to anywhere on the system.",
    )
    p.add_argument(
        "--links",
        metavar="FILE",
        default=None,
        help="Path to links JSON file (default: <repo>/dotfiles.json)",
    )

    sub = p.add_subparsers(dest="cmd", required=True)

    # add
    pa = sub.add_parser("add", help="Add a new link entry to dotfiles.json")
    pa.add_argument("src", help="Source path (relative to repo or absolute)")
    pa.add_argument("dst", help="Destination path (supports ~)")

    # status
    ps = sub.add_parser("status", help="Show link status")
    ps.add_argument(
        "--only",
        metavar="PATTERN",
        help="Filter to links whose src or dst contains PATTERN",
    )

    # install
    pi = sub.add_parser("install", help="Create/update symlinks")
    pi.add_argument(
        "--force",
        action="store_true",
        help="Relink symlinks pointing to the wrong target",
    )
    pi.add_argument(
        "--only",
        metavar="PATTERN",
        help="Filter to links whose src or dst contains PATTERN",
    )

    # remove (renamed from clean)
    pr = sub.add_parser("remove", help="Remove symlinks that point into this repo")
    pr.add_argument(
        "--only",
        metavar="PATTERN",
        help="Filter to links whose src or dst contains PATTERN",
    )

    # backup
    pb = sub.add_parser(
        "backup",
        help="Copy files/dirs blocking link destinations to <dst>.bkp (no deletion)",
    )
    pb.add_argument(
        "--only",
        metavar="PATTERN",
        help="Filter to links whose src or dst contains PATTERN",
    )

    # delete
    pd = sub.add_parser(
        "delete", help="Move files/dirs blocking link destinations to trash"
    )
    pd.add_argument(
        "--only",
        metavar="PATTERN",
        help="Filter to links whose src or dst contains PATTERN",
    )

    return p


def main(argv: List[str]) -> int:
    args = build_parser().parse_args(argv)

    links_file = Path(args.links) if args.links else repo_dir() / "dotfiles.json"

    if args.cmd == "add":
        cmd_add(links_file, args.src, args.dst)
        return 0

    links_json = json.loads(links_file.read_text())
    links = Manifest.from_dict(links_json, repo_dir())

    only = getattr(args, "only", None)

    if args.cmd == "status":
        links.status(only)
    elif args.cmd == "install":
        links.install(force_install=args.force, only=only)
    elif args.cmd == "remove":
        links.remove(only)
    elif args.cmd == "backup":
        links.backup(only)
    elif args.cmd == "delete":
        links.delete(only)
    else:
        panic(f"Unknown command: {args.cmd}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import List


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
        src = Path(d["src"])  # Provided as absolute or relative to repo
        dst = Path(d["dst"])  # Provided as absolute always

        src = src if src.is_absolute() else (src_base / src)
        dst = dst.expanduser()  # Expand ~ in destination

        src = src.resolve()

        if not src.exists():
            panic(f"Source does not exist: {src}")

        if dst.exists() and not dst.is_symlink():
            panic(f"Destination already exists and is not a symlink: {dst}")

        return Link(src=src, dst=dst)

    def create(self):
        self.dst.parent.mkdir(parents=True, exist_ok=True)
        os.symlink(self.src, self.dst)

    def exists(self) -> bool:
        return self.dst.is_symlink() and symlink_target(self.dst) == self.src

    def is_dir(self) -> bool:
        return self.src.is_dir()

    def is_file(self) -> bool:
        return self.src.is_file()

    def remove(self):
        """Remove the symlink at dst if it exists."""
        if self.exists():
            self.dst.unlink()


@dataclass(frozen=True)
class Manifest:
    """A collection of symlink declarations with the context needed to apply them."""

    links: List[Link]

    @staticmethod
    def from_dict(d: dict, src_base: Path) -> Manifest:
        links = [Link.from_dict(item, src_base) for item in d["links"]]
        return Manifest(links=links)

    def status(self):
        for link in self.links:
            if link.exists():
                print(f"LINKED     {link.dst} -> {link.src}")
            elif link.dst.is_symlink():  # dst is symlink, but points to wrong target
                tgt = symlink_target(link.dst)
                pretty = pretty_home_path(tgt)
                print(f"WRONG LINK {link.dst} -> {pretty} (expected {link.src})")
            else:
                print(f"NOT LINKED {link.dst}")

    def install(self, force_install: bool):
        """
        Create symlinks as declared in the manifest
        force_install: if True, will remove existing files/links at the destination if they don't point to the source
        """
        for link in self.links:
            if link.exists():
                print(f"SKIP       {link.dst} -> {link.src}")
            elif not link.dst.is_symlink():  # dst doesn't exist or is not a symlink
                print(f"++ LINK    {link.dst} -> {link.src}")
                link.create()
            elif force_install:
                tgt = symlink_target(link.dst)
                print(f"!! RELINK  {link.dst} -> {tgt}, expected -> {link.src})")
                link.dst.unlink()
                link.create()
            else:
                tgt = symlink_target(link.dst)
                print(f"!! SKIP    {link.dst} -> {tgt}, use --force to relink")

    def clean(self):
        for link in self.links:
            if link.exists():
                print(f"-- REMOVE  {link.dst}")
                link.remove()


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
    sub.add_parser("status", help="Show link status")
    pi = sub.add_parser("install", help="Create/update symlinks")
    pi.add_argument(
        "--force",
        action="store_true",
        help="Relink symlinks pointing to the wrong target",
    )
    sub.add_parser("clean", help="Remove symlinks that point into this repo")

    return p


def main(argv: List[str]) -> int:
    args = build_parser().parse_args(argv)

    links_file = Path(args.links) if args.links else repo_dir() / "dotfiles.json"
    links_json = json.loads(links_file.read_text())
    manifest = Manifest.from_dict(links_json, repo_dir())

    if args.cmd == "status":
        manifest.status()
    elif args.cmd == "install":
        manifest.install(force_install=args.force)
    elif args.cmd == "clean":
        manifest.clean()
    else:
        panic(f"Unknown command: {args.cmd}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

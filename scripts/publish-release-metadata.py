#!/usr/bin/env python3
"""
Script to publish release metadata to a JSON file for GitHub Pages.

Maps Proton-GE versions to GitHub Releases on this repository containing
built Wine prefix tarballs.

The metadata file structure:
{
  "repository": "DeckCheatz/BuiltPrefixes",
  "updated_at": "2024-01-15T12:00:00Z",
  "releases": {
    "GE-Proton9-20": {
      "proton_version": "GE-Proton9-20",
      "release_tag": "prefix-GE-Proton9-20",
      "release_url": "https://github.com/DeckCheatz/BuiltPrefixes/releases/tag/prefix-GE-Proton9-20",
      "tarball_url": "https://github.com/DeckCheatz/BuiltPrefixes/releases/download/prefix-GE-Proton9-20/wine-prefix-GE-Proton9-20.tar.gz",
      "tarball_sha256": "abc123...",
      "created_at": "2024-01-15T12:00:00Z",
      "arch": "x86_64"
    }
  }
}

Usage:
  ./scripts/publish-release-metadata.py add GE-Proton9-20 --tarball ./output/prefix.tar.gz
  ./scripts/publish-release-metadata.py add GE-Proton9-20 --sha256 abc123...
  ./scripts/publish-release-metadata.py remove GE-Proton9-20
  ./scripts/publish-release-metadata.py list
  ./scripts/publish-release-metadata.py sync --from-github
"""

import argparse
import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional


DEFAULT_METADATA_FILE = "docs/releases.json"
DEFAULT_REPO = os.environ.get("GITHUB_REPOSITORY", "DeckCheatz/BuiltPrefixes")


def get_iso_timestamp() -> str:
    """Get current UTC timestamp in ISO format."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def calculate_sha256(file_path: Path) -> str:
    """Calculate SHA256 checksum of a file."""
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(8192), b""):
            sha256_hash.update(chunk)
    return sha256_hash.hexdigest()


def load_metadata(metadata_file: Path) -> dict:
    """Load existing metadata or create empty structure."""
    if metadata_file.exists():
        with open(metadata_file, "r") as f:
            return json.load(f)
    return {
        "repository": DEFAULT_REPO,
        "updated_at": get_iso_timestamp(),
        "releases": {}
    }


def save_metadata(metadata: dict, metadata_file: Path) -> None:
    """Save metadata to file."""
    metadata["updated_at"] = get_iso_timestamp()
    metadata_file.parent.mkdir(parents=True, exist_ok=True)
    with open(metadata_file, "w") as f:
        json.dump(metadata, f, indent=2, sort_keys=False)
        f.write("\n")


def get_release_tag(proton_version: str, arch: str = "x86_64") -> str:
    """Generate release tag name for a Proton version."""
    if arch == "x86_64":
        return f"prefix-{proton_version}"
    return f"prefix-{proton_version}-{arch}"


def get_tarball_name(proton_version: str, arch: str = "x86_64") -> str:
    """Generate tarball filename for a Proton version."""
    if arch == "x86_64":
        return f"wine-prefix-{proton_version}.tar.gz"
    return f"wine-prefix-{proton_version}-{arch}.tar.gz"


def build_release_entry(
    proton_version: str,
    repo: str,
    sha256: Optional[str] = None,
    arch: str = "x86_64"
) -> dict:
    """Build a release metadata entry."""
    release_tag = get_release_tag(proton_version, arch)
    tarball_name = get_tarball_name(proton_version, arch)

    return {
        "proton_version": proton_version,
        "release_tag": release_tag,
        "release_url": f"https://github.com/{repo}/releases/tag/{release_tag}",
        "tarball_url": f"https://github.com/{repo}/releases/download/{release_tag}/{tarball_name}",
        "tarball_name": tarball_name,
        "tarball_sha256": sha256 or "",
        "created_at": get_iso_timestamp(),
        "arch": arch
    }


def cmd_add(args) -> int:
    """Add or update a release entry."""
    metadata = load_metadata(args.metadata_file)

    # Calculate SHA256 if tarball provided
    sha256 = args.sha256
    if args.tarball:
        tarball_path = Path(args.tarball)
        if not tarball_path.exists():
            print(f"Error: Tarball not found: {tarball_path}", file=sys.stderr)
            return 1
        sha256 = calculate_sha256(tarball_path)
        print(f"Calculated SHA256: {sha256}")

    # Build entry
    entry = build_release_entry(
        proton_version=args.version,
        repo=args.repo,
        sha256=sha256,
        arch=args.arch
    )

    # Use composite key for multi-arch support
    entry_key = args.version if args.arch == "x86_64" else f"{args.version}-{args.arch}"

    metadata["releases"][entry_key] = entry
    metadata["repository"] = args.repo

    save_metadata(metadata, args.metadata_file)

    print(f"Added release entry for {args.version} ({args.arch}):")
    print(json.dumps(entry, indent=2))

    return 0


def cmd_remove(args) -> int:
    """Remove a release entry."""
    metadata = load_metadata(args.metadata_file)

    entry_key = args.version if args.arch == "x86_64" else f"{args.version}-{args.arch}"

    if entry_key not in metadata["releases"]:
        print(f"Warning: No entry found for {entry_key}", file=sys.stderr)
        return 0

    del metadata["releases"][entry_key]
    save_metadata(metadata, args.metadata_file)

    print(f"Removed release entry for {entry_key}")
    return 0


def cmd_list(args) -> int:
    """List all release entries."""
    metadata = load_metadata(args.metadata_file)

    if not metadata["releases"]:
        print("No releases found")
        return 0

    if args.json:
        print(json.dumps(metadata, indent=2))
    else:
        print(f"Repository: {metadata.get('repository', 'unknown')}")
        print(f"Last updated: {metadata.get('updated_at', 'unknown')}")
        print(f"\nReleases ({len(metadata['releases'])}):")
        print("-" * 60)

        for key, entry in sorted(metadata["releases"].items()):
            sha_display = entry.get("tarball_sha256", "")[:16]
            if sha_display:
                sha_display = f"{sha_display}..."
            else:
                sha_display = "(no checksum)"

            print(f"  {entry['proton_version']:20} {entry.get('arch', 'x86_64'):8} {sha_display}")

    return 0


def cmd_sync(args) -> int:
    """Sync metadata from GitHub releases."""
    try:
        # Use gh CLI to list releases
        result = subprocess.run(
            ["gh", "release", "list", "--repo", args.repo, "--json",
             "tagName,createdAt,assets", "--limit", "100"],
            capture_output=True,
            text=True,
            check=True
        )
        releases = json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error fetching releases: {e.stderr}", file=sys.stderr)
        return 1
    except FileNotFoundError:
        print("Error: gh CLI not found. Install GitHub CLI.", file=sys.stderr)
        return 1

    metadata = load_metadata(args.metadata_file)

    # Filter and process prefix releases
    prefix_releases = [r for r in releases if r["tagName"].startswith("prefix-")]

    added = 0
    for release in prefix_releases:
        tag = release["tagName"]

        # Parse version from tag (prefix-GE-Proton9-20 or prefix-GE-Proton9-20-i686)
        parts = tag.replace("prefix-", "").rsplit("-", 1)
        if len(parts) == 2 and parts[1] in ("i686", "i386"):
            proton_version = parts[0]
            arch = parts[1]
        else:
            proton_version = tag.replace("prefix-", "")
            arch = "x86_64"

        entry_key = proton_version if arch == "x86_64" else f"{proton_version}-{arch}"

        # Skip if already exists and not forcing
        if entry_key in metadata["releases"] and not args.force:
            continue

        # Find tarball asset
        tarball_asset = None
        for asset in release.get("assets", []):
            if asset["name"].endswith(".tar.gz"):
                tarball_asset = asset
                break

        entry = build_release_entry(
            proton_version=proton_version,
            repo=args.repo,
            sha256=None,  # Would need to download to calculate
            arch=arch
        )
        entry["created_at"] = release["createdAt"]

        metadata["releases"][entry_key] = entry
        added += 1
        print(f"Added: {entry_key}")

    if added > 0:
        metadata["repository"] = args.repo
        save_metadata(metadata, args.metadata_file)
        print(f"\nSynced {added} release(s)")
    else:
        print("No new releases to sync")

    return 0


def cmd_get_url(args) -> int:
    """Get download URL for a specific version."""
    metadata = load_metadata(args.metadata_file)

    entry_key = args.version if args.arch == "x86_64" else f"{args.version}-{args.arch}"

    if entry_key not in metadata["releases"]:
        print(f"Error: No entry found for {entry_key}", file=sys.stderr)
        return 1

    entry = metadata["releases"][entry_key]

    if args.field == "tarball":
        print(entry["tarball_url"])
    elif args.field == "release":
        print(entry["release_url"])
    elif args.field == "sha256":
        print(entry.get("tarball_sha256", ""))
    elif args.field == "json":
        print(json.dumps(entry, indent=2))

    return 0


def main():
    parser = argparse.ArgumentParser(
        description="Manage release metadata for GitHub Pages",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s add GE-Proton9-20 --tarball ./output/prefix.tar.gz
  %(prog)s add GE-Proton9-20 --sha256 abc123...
  %(prog)s add GE-Proton9-20 --arch i686 --tarball ./output/prefix-i686.tar.gz
  %(prog)s remove GE-Proton9-20
  %(prog)s list
  %(prog)s list --json
  %(prog)s sync --from-github
  %(prog)s get-url GE-Proton9-20

GitHub Actions usage:
  - name: Update release metadata
    run: |
      ./scripts/publish-release-metadata.py add "${{ matrix.version }}" \\
        --tarball ./output/wine-prefix.tar.gz

  - name: Deploy to GitHub Pages
    uses: peaceiris/actions-gh-pages@v3
    with:
      github_token: ${{ secrets.GITHUB_TOKEN }}
      publish_dir: ./docs
"""
    )

    parser.add_argument(
        "--metadata-file", "-f",
        type=Path,
        default=Path(DEFAULT_METADATA_FILE),
        help=f"Path to metadata JSON file (default: {DEFAULT_METADATA_FILE})"
    )
    parser.add_argument(
        "--repo", "-r",
        default=DEFAULT_REPO,
        help=f"GitHub repository (default: {DEFAULT_REPO})"
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    # Add command
    add_parser = subparsers.add_parser("add", help="Add or update a release entry")
    add_parser.add_argument("version", help="Proton-GE version (e.g., GE-Proton9-20)")
    add_parser.add_argument("--tarball", "-t", type=Path, help="Path to tarball (calculates SHA256)")
    add_parser.add_argument("--sha256", "-s", help="SHA256 checksum (if tarball not provided)")
    add_parser.add_argument("--arch", "-a", default="x86_64", choices=["x86_64", "i686", "i386"],
                           help="Architecture (default: x86_64)")
    add_parser.set_defaults(func=cmd_add)

    # Remove command
    remove_parser = subparsers.add_parser("remove", help="Remove a release entry")
    remove_parser.add_argument("version", help="Proton-GE version to remove")
    remove_parser.add_argument("--arch", "-a", default="x86_64", help="Architecture")
    remove_parser.set_defaults(func=cmd_remove)

    # List command
    list_parser = subparsers.add_parser("list", help="List all release entries")
    list_parser.add_argument("--json", "-j", action="store_true", help="Output as JSON")
    list_parser.set_defaults(func=cmd_list)

    # Sync command
    sync_parser = subparsers.add_parser("sync", help="Sync metadata from GitHub releases")
    sync_parser.add_argument("--from-github", action="store_true", dest="from_github",
                            help="Fetch releases from GitHub")
    sync_parser.add_argument("--force", action="store_true", help="Overwrite existing entries")
    sync_parser.set_defaults(func=cmd_sync)

    # Get URL command
    get_parser = subparsers.add_parser("get-url", help="Get URL for a version")
    get_parser.add_argument("version", help="Proton-GE version")
    get_parser.add_argument("--arch", "-a", default="x86_64", help="Architecture")
    get_parser.add_argument("--field", "-F", default="tarball",
                           choices=["tarball", "release", "sha256", "json"],
                           help="Field to output (default: tarball)")
    get_parser.set_defaults(func=cmd_get_url)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""
Script to update the Proton-GE configuration in include/proton-ge-config.yml
"""

import argparse
import hashlib
import sys
import tempfile
import urllib.error
import urllib.request
from pathlib import Path


def release_asset_urls(version: str) -> list[str]:
    """Candidate release archive URLs for a version, newest naming first.

    Newer GE-Proton releases (GE-Proton11-x onward) publish an
    architecture-suffixed tarball (e.g. GE-Proton11-6-x86_64.tar.gz)
    alongside an aarch64 build. Older releases only ever published the
    unsuffixed tarball, so fall back to that name if the suffixed one
    isn't found.
    """
    base = f"https://github.com/GloriousEggroll/proton-ge-custom/releases/download/{version}"
    return [
        f"{base}/{version}-x86_64.tar.gz",
        f"{base}/{version}.tar.gz",
    ]


def calculate_sha256(url: str) -> str:
    """Download a file and calculate its SHA256 checksum."""
    print(f"Downloading {url}...")
    try:
        with urllib.request.urlopen(url) as response:
            sha256_hash = hashlib.sha256()
            while chunk := response.read(8192):
                sha256_hash.update(chunk)
            return sha256_hash.hexdigest()
    except Exception as e:
        print(f"Error downloading {url}: {e}", file=sys.stderr)
        return ""


def find_release_asset(version: str) -> tuple[str, str]:
    """Find the first available release archive URL and its checksum."""
    for url in release_asset_urls(version):
        try:
            urllib.request.urlopen(urllib.request.Request(url, method='HEAD'))
        except urllib.error.HTTPError as e:
            if e.code == 404:
                print(f"{url} not found, trying next candidate...", file=sys.stderr)
                continue
            raise
        checksum = calculate_sha256(url)
        if checksum:
            return url, checksum
    return "", ""


def to_github_alias(url: str) -> str:
    """Convert a https://github.com/... URL to the buildstream `github:` alias form."""
    return url.replace("https://github.com/", "github:", 1)


def update_config(version: str, checksum: str, url: str, output_file: Path) -> bool:
    """Update the Proton-GE configuration file with new version and checksum."""
    try:
        config_content = f"""variables:
  proton_ge_version: "{version}"
  proton_ge_hash: "{checksum}"
  proton_ge_url: "{to_github_alias(url)}"
"""
        
        # Write to temporary file first, then move to ensure atomicity
        with tempfile.NamedTemporaryFile(mode='w', dir=output_file.parent, delete=False) as tmp:
            tmp.write(config_content)
            tmp_path = Path(tmp.name)
        
        # Move temporary file to final location
        tmp_path.replace(output_file)
        
        print(f"Updated {output_file} with Proton-GE {version}")
        print(f"Version: {version}")
        print(f"Hash: {checksum}")
        print(f"URL: {url}")
        
        return True
        
    except Exception as e:
        print(f"Error updating configuration: {e}", file=sys.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(
        description='Update Proton-GE configuration in include/proton-ge-config.yml'
    )
    parser.add_argument('version', help='Proton-GE version (e.g., GE-Proton10-25)')
    parser.add_argument('checksum', nargs='?', help='SHA256 checksum of the release archive')
    parser.add_argument(
        '--url',
        help='Explicit release archive URL to use (skips auto-detection)'
    )
    parser.add_argument(
        '--config-file', '-c',
        type=Path,
        default=Path('include/proton-ge-config.yml'),
        help='Path to config file (default: include/proton-ge-config.yml)'
    )
    parser.add_argument(
        '--calculate-checksum', '--calc',
        action='store_true',
        help='Calculate checksum by downloading the release archive'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show checksum without updating config file'
    )

    args = parser.parse_args()

    # Validate inputs
    if not args.version:
        print("Error: Version cannot be empty", file=sys.stderr)
        sys.exit(1)

    # Calculate checksum if requested or if no checksum provided
    if args.calculate_checksum or not args.checksum:
        if args.url:
            url = args.url
            checksum = calculate_sha256(url)
        else:
            url, checksum = find_release_asset(args.version)

        if not checksum:
            print(f"Failed to calculate checksum for {args.version}", file=sys.stderr)
            sys.exit(1)

        print(f"SHA256 checksum for {args.version}: {checksum}")
        print(f"URL: {url}")

        if args.dry_run:
            print("Dry run - configuration not updated")
            sys.exit(0)

        args.checksum = checksum
        args.url = url

    # Validate checksum format
    if not args.checksum or len(args.checksum) != 64:
        print("Error: Checksum must be a 64-character SHA256 hash", file=sys.stderr)
        sys.exit(1)

    # If a checksum was supplied explicitly without --calc, we still need a URL
    if not args.url:
        args.url = release_asset_urls(args.version)[0]

    # Ensure parent directory exists
    args.config_file.parent.mkdir(parents=True, exist_ok=True)

    # Update configuration
    if update_config(args.version, args.checksum, args.url, args.config_file):
        print(f"Configuration successfully updated!")
        sys.exit(0)
    else:
        print("Failed to update configuration", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

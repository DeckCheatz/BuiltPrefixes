#!/usr/bin/env python3
"""
Script to update the Proton-GE configuration in include/proton-ge-config.yml
"""

import argparse
import hashlib
import sys
import tempfile
import urllib.request
from pathlib import Path


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


def update_config(version: str, checksum: str, output_file: Path) -> bool:
    """Update the Proton-GE configuration file with new version and checksum."""
    try:
        url = f"https://github.com/GloriousEggroll/proton-ge-custom/releases/download/{version}/{version}.tar.gz"
        
        config_content = f"""variables:
  proton_ge_version: "{version}"
  proton_ge_hash: "{checksum}"
  proton_ge_url: "{url}"
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
        url = f"https://github.com/GloriousEggroll/proton-ge-custom/releases/download/{args.version}/{args.version}.tar.gz"
        checksum = calculate_sha256(url)
        if not checksum:
            print("Failed to calculate checksum", file=sys.stderr)
            sys.exit(1)
        
        print(f"SHA256 checksum for {args.version}: {checksum}")
        print(f"URL: {url}")
        
        if args.dry_run:
            print("Dry run - configuration not updated")
            sys.exit(0)
        
        args.checksum = checksum
    
    # Validate checksum format
    if not args.checksum or len(args.checksum) != 64:
        print("Error: Checksum must be a 64-character SHA256 hash", file=sys.stderr)
        sys.exit(1)
    
    # Ensure parent directory exists
    args.config_file.parent.mkdir(parents=True, exist_ok=True)
    
    # Update configuration
    if update_config(args.version, args.checksum, args.config_file):
        print(f"Configuration successfully updated!")
        sys.exit(0)
    else:
        print("Failed to update configuration", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()

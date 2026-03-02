#!/usr/bin/env python3
"""
Script to generate a GitHub Actions matrix of Proton-GE versions from X to Y.

Output format is JSON suitable for use with GitHub Actions dynamic matrix:
  {"include": [{"version": "GE-Proton9-1"}, {"version": "GE-Proton9-2"}, ...]}

Usage:
  ./scripts/generate-proton-matrix.py GE-Proton9-1 GE-Proton9-20
  ./scripts/generate-proton-matrix.py GE-Proton8-25 GE-Proton9-5 --verify
"""

import argparse
import json
import re
import sys
import urllib.request
from dataclasses import dataclass
from typing import Optional


@dataclass
class ProtonVersion:
    """Represents a Proton-GE version."""
    major: int
    minor: int

    VERSION_PATTERN = re.compile(r'^GE-Proton(\d+)-(\d+)$')

    @classmethod
    def parse(cls, version_str: str) -> Optional['ProtonVersion']:
        """Parse a version string like 'GE-Proton9-20' into a ProtonVersion."""
        match = cls.VERSION_PATTERN.match(version_str)
        if not match:
            return None
        return cls(major=int(match.group(1)), minor=int(match.group(2)))

    def __str__(self) -> str:
        return f"GE-Proton{self.major}-{self.minor}"

    def __lt__(self, other: 'ProtonVersion') -> bool:
        if self.major != other.major:
            return self.major < other.major
        return self.minor < other.minor

    def __le__(self, other: 'ProtonVersion') -> bool:
        return self == other or self < other

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, ProtonVersion):
            return NotImplemented
        return self.major == other.major and self.minor == other.minor

    def __hash__(self) -> int:
        return hash((self.major, self.minor))


def generate_version_range(start: ProtonVersion, end: ProtonVersion) -> list[ProtonVersion]:
    """
    Generate all versions between start and end (inclusive).

    Handles cross-major version ranges by assuming minor versions
    reset to 1 when major version increments.
    """
    if end < start:
        raise ValueError(f"End version {end} must be >= start version {start}")

    versions = []
    current_major = start.major
    current_minor = start.minor

    while True:
        version = ProtonVersion(major=current_major, minor=current_minor)

        if version > end:
            break

        versions.append(version)

        if version == end:
            break

        # Increment version
        if current_major < end.major:
            # For cross-major ranges, we increment minor until we need to jump major
            # This is a heuristic - we assume minor versions go up to a reasonable max
            # and then we jump to the next major version starting at 1
            current_minor += 1
            # Heuristic: if minor > 50 or we've reached a reasonable stopping point,
            # jump to next major. In practice, you may want to use --verify mode
            # or provide explicit version lists for cross-major ranges.
            if current_minor > 50:
                current_major += 1
                current_minor = 1
        else:
            current_minor += 1

    return versions


def verify_version_exists(version: ProtonVersion) -> bool:
    """Check if a Proton-GE release exists on GitHub."""
    url = f"https://github.com/GloriousEggroll/proton-ge-custom/releases/tag/{version}"
    try:
        request = urllib.request.Request(url, method='HEAD')
        with urllib.request.urlopen(request, timeout=10) as response:
            return response.status == 200
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return False
        # Other errors - assume it might exist
        return True
    except Exception:
        # Network errors - assume it might exist
        return True


def generate_matrix(
    versions: list[ProtonVersion],
    verify: bool = False,
    include_url: bool = False
) -> dict:
    """Generate a GitHub Actions matrix from a list of versions."""
    include_list = []

    for version in versions:
        if verify:
            if not verify_version_exists(version):
                print(f"Skipping {version} (not found on GitHub)", file=sys.stderr)
                continue
            print(f"Verified {version} exists", file=sys.stderr)

        entry = {"version": str(version)}

        if include_url:
            entry["url"] = (
                f"https://github.com/GloriousEggroll/proton-ge-custom/releases/download/"
                f"{version}/{version}.tar.gz"
            )

        include_list.append(entry)

    return {"include": include_list}


def main():
    parser = argparse.ArgumentParser(
        description='Generate a GitHub Actions matrix of Proton-GE versions',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s GE-Proton9-1 GE-Proton9-20
  %(prog)s GE-Proton9-15 GE-Proton9-20 --verify
  %(prog)s GE-Proton9-1 GE-Proton9-5 --include-url

GitHub Actions usage:
  jobs:
    generate-matrix:
      runs-on: ubuntu-latest
      outputs:
        matrix: ${{ steps.matrix.outputs.matrix }}
      steps:
        - uses: actions/checkout@v4
        - id: matrix
          run: |
            MATRIX=$(./scripts/generate-proton-matrix.py "${{ inputs.start }}" "${{ inputs.end }}")
            echo "matrix=$MATRIX" >> $GITHUB_OUTPUT

    build:
      needs: generate-matrix
      strategy:
        matrix: ${{ fromJson(needs.generate-matrix.outputs.matrix) }}
      steps:
        - run: echo "Building ${{ matrix.version }}"
"""
    )

    parser.add_argument(
        'start_version',
        help='Start version (e.g., GE-Proton9-1)'
    )
    parser.add_argument(
        'end_version',
        help='End version (e.g., GE-Proton9-20)'
    )
    parser.add_argument(
        '--verify',
        action='store_true',
        help='Verify each version exists on GitHub (slower but accurate)'
    )
    parser.add_argument(
        '--include-url',
        action='store_true',
        help='Include download URL in matrix output'
    )
    parser.add_argument(
        '--pretty',
        action='store_true',
        help='Pretty-print JSON output'
    )
    parser.add_argument(
        '--versions-only',
        action='store_true',
        help='Output only version strings, one per line (not JSON)'
    )

    args = parser.parse_args()

    # Parse versions
    start = ProtonVersion.parse(args.start_version)
    if not start:
        print(
            f"Error: Invalid start version format '{args.start_version}'. "
            "Expected format: GE-ProtonX-Y (e.g., GE-Proton9-1)",
            file=sys.stderr
        )
        sys.exit(1)

    end = ProtonVersion.parse(args.end_version)
    if not end:
        print(
            f"Error: Invalid end version format '{args.end_version}'. "
            "Expected format: GE-ProtonX-Y (e.g., GE-Proton9-20)",
            file=sys.stderr
        )
        sys.exit(1)

    # Generate version range
    try:
        versions = generate_version_range(start, end)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    if not versions:
        print("Error: No versions generated", file=sys.stderr)
        sys.exit(1)

    # Output versions only if requested
    if args.versions_only:
        for version in versions:
            if args.verify:
                if verify_version_exists(version):
                    print(version)
                else:
                    print(f"Skipping {version} (not found)", file=sys.stderr)
            else:
                print(version)
        sys.exit(0)

    # Generate and output matrix
    matrix = generate_matrix(
        versions,
        verify=args.verify,
        include_url=args.include_url
    )

    if not matrix["include"]:
        print("Error: No valid versions found", file=sys.stderr)
        sys.exit(1)

    if args.pretty:
        print(json.dumps(matrix, indent=2))
    else:
        print(json.dumps(matrix))


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Wrapper script to update Proton-GE config and track the source in BuildStream.

This script:
1. Calls update-proton-config.py with the provided arguments
2. Runs 'bst source track' on components/proton-ge-custom.bst
"""

import subprocess
import sys
from pathlib import Path


def main():
    # Get the script directory and project root
    script_dir = Path(__file__).parent
    project_root = script_dir.parent

    # Path to the update-proton-config.py script
    update_script = script_dir / "update-proton-config.py"

    # Path to the BuildStream element
    bst_element = "components/proton-ge-custom.bst"

    # Call update-proton-config.py with all arguments passed to this script
    print("=== Updating Proton-GE configuration ===")
    try:
        result = subprocess.run(
            [sys.executable, str(update_script)] + sys.argv[1:],
            cwd=project_root,
            check=True
        )
    except subprocess.CalledProcessError as e:
        print(f"Error: Failed to update Proton-GE configuration (exit code {e.returncode})", file=sys.stderr)
        sys.exit(e.returncode)

    # If config update succeeded, track the source in BuildStream
    print("\n=== Tracking Proton-GE source in BuildStream ===")
    try:
        result = subprocess.run(
            ["bst", "source", "track", bst_element],
            cwd=project_root,
            check=True
        )
        print(f"\nSuccessfully tracked source for {bst_element}")
    except subprocess.CalledProcessError as e:
        print(f"Error: Failed to track BuildStream source (exit code {e.returncode})", file=sys.stderr)
        sys.exit(e.returncode)
    except FileNotFoundError:
        print("Error: 'bst' command not found. Is BuildStream installed?", file=sys.stderr)
        sys.exit(1)

    print("\n=== All operations completed successfully! ===")
    sys.exit(0)


if __name__ == "__main__":
    main()

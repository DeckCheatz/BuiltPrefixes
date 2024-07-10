#!/usr/bin/env bash

set -euo pipefail

# fetch-proton-releases.sh - Common script for fetching Proton release information
# Usage: ./scripts/fetch-proton-releases.sh [OPTIONS] [VENDOR] [OUTPUT_FORMAT]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CACHE_DIR="${PROJECT_ROOT}/.cache"

# GitHub API settings
GITHUB_API_GE="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases"
GITHUB_API_VALVE="https://api.github.com/repos/ValveSoftware/Proton/releases"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

# Default parameters  
VENDOR="${1:-proton-ge}"      # only proton-ge (valve doesn't provide binaries)
OUTPUT_FORMAT="${2:-urls}"    # urls, json, human, versions
COUNT="${3:-10}"              # number of releases to return
CACHE_TTL="${CACHE_TTL:-3600}" # cache time-to-live in seconds

# Create necessary directories
mkdir -p "$CACHE_DIR"

# Function to show usage
usage() {
    cat << EOF
Usage: $0 [VENDOR] [OUTPUT_FORMAT] [COUNT]

Fetch Proton release information from GitHub and output in various formats.

Vendors:
  both           Fetch both Proton-GE and Valve Proton releases (default)
  proton-ge      Fetch only Proton-GE releases
  valve          Fetch only Valve Proton releases

Output Formats:
  urls           Output release URLs suitable for --override-input (default)
  json           Output raw JSON data
  human          Human-readable format for display
  versions       Output only version tags
  build-args     Output build arguments for nix build commands

Options:
  COUNT          Number of releases to return (default: 10)

Environment Variables:
  GITHUB_TOKEN   GitHub API token for higher rate limits
  CACHE_TTL      Cache time-to-live in seconds (default: 3600)

Examples:
  $0 proton-ge urls 5          # Get 5 latest Proton-GE URLs
  $0 proton-ge human 3         # Get 3 latest Proton-GE releases in human format
  $0 proton-ge versions 10     # Get 10 latest Proton-GE versions
  $0 proton-ge build-args 1    # Get build arguments for latest Proton-GE

Output Examples:

  urls format:
    proton-ge|GE-Proton10-10|https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton10-10/GE-Proton10-10.tar.gz

  build-args format:
    --override-input proton-src "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton10-10/GE-Proton10-10.tar.gz"

  human format:
    🎮 Proton-GE Releases:
      GE-Proton10-10 - 2024-12-15 - Proton-GE 10-10
    🔧 Valve Proton Releases:
      proton-9.0-4 - 2024-12-11 - Proton 9.0-4

EOF
}

# Function to check if cache is valid
is_cache_valid() {
    local cache_file="$1"
    
    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi
    
    local file_age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
    
    if [[ $file_age -gt $CACHE_TTL ]]; then
        return 1
    fi
    
    return 0
}

# Function to fetch releases from GitHub API
fetch_releases() {
    local api_url="$1"
    local cache_file="$2"
    local repo_name="$3"
    
    # Check cache first
    if is_cache_valid "$cache_file"; then
        return 0
    fi
    
    local curl_args=(-s)
    
    if [[ -n "$GITHUB_TOKEN" ]]; then
        curl_args+=(-H "Authorization: token $GITHUB_TOKEN")
    fi
    
    echo "Fetching $repo_name releases from GitHub API..." >&2
    if curl "${curl_args[@]}" "$api_url" > "$cache_file.tmp"; then
        if jq empty "$cache_file.tmp" 2>/dev/null; then
            mv "$cache_file.tmp" "$cache_file"
            echo "✓ Successfully fetched $repo_name release data" >&2
        else
            echo "Error: Invalid JSON response from $repo_name GitHub API" >&2
            rm -f "$cache_file.tmp"
            return 1
        fi
    else
        echo "Error: Failed to fetch $repo_name releases" >&2
        rm -f "$cache_file.tmp"
        return 1
    fi
}

# Function to convert tag to archive URL
tag_to_archive_url() {
    local vendor="$1"
    local tag="$2"
    
    case "$vendor" in
        "proton-ge")
            echo "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${tag}/${tag}.tar.gz"
            ;;
        "valve")
            echo "Error: Valve Proton doesn't provide pre-built binaries" >&2
            return 1
            ;;
        *)
            echo "Error: Unknown vendor '$vendor'" >&2
            return 1
            ;;
    esac
}

# Function to process releases for a vendor
process_vendor_releases() {
    local vendor="$1"
    local format="$2"
    local count="$3"
    local cache_file="$4"
    
    if [[ ! -f "$cache_file" ]]; then
        echo "Error: Cache file not found for $vendor" >&2
        return 1
    fi
    
    case "$format" in
        "urls")
            jq -r --argjson count "$count" '.[:$count] | .[] | "\(.tag_name)"' "$cache_file" | \
            while read -r tag; do
                if [[ -n "$tag" && "$tag" != "null" ]]; then
                    local url=$(tag_to_archive_url "$vendor" "$tag")
                    echo "$vendor|$tag|$url"
                fi
            done
            ;;
        "json")
            jq -r --argjson count "$count" '.[:$count]' "$cache_file"
            ;;
        "human")
            jq -r --argjson count "$count" '.[:$count] | .[] | "  \(.tag_name) - \(.published_at[:10]) - \(.name)"' "$cache_file"
            ;;
        "versions")
            jq -r --argjson count "$count" '.[:$count] | .[] | .tag_name' "$cache_file"
            ;;
        "build-args")
            jq -r --argjson count "$count" '.[:$count] | .[] | "\(.tag_name)"' "$cache_file" | \
            while read -r tag; do
                if [[ -n "$tag" && "$tag" != "null" ]]; then
                    local url=$(tag_to_archive_url "$vendor" "$tag")
                    echo "--override-input proton-src \"$url\""
                fi
            done
            ;;
        *)
            echo "Error: Unknown output format '$format'" >&2
            return 1
            ;;
    esac
}

# Function to output human-readable header
output_human_header() {
    local vendor="$1"
    local count="$2"
    
    case "$vendor" in
        "proton-ge")
            echo "🎮 Proton-GE Releases (latest $count):"
            echo "----------------------------------------"
            ;;
        "valve")
            echo "🔧 Valve Proton Releases (latest $count):"
            echo "-------------------------------------------"
            ;;
        "both")
            echo "Available Proton Releases (latest $count each)"
            echo "=============================================="
            echo ""
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        --count)
            COUNT="$2"
            shift 2
            ;;
        --cache-ttl)
            CACHE_TTL="$2"
            shift 2
            ;;
        --no-cache)
            # Force refresh by setting cache files to be very old
            find "$CACHE_DIR" -name "releases-*.json" -exec touch -d "1970-01-01" {} \; 2>/dev/null || true
            shift
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage
            exit 1
            ;;
        *)
            # Positional arguments are handled above
            break
            ;;
    esac
done

# Validate parameters
case "$VENDOR" in
    "proton-ge") ;;
    "valve")
        echo "Error: Valve Proton doesn't provide pre-built binaries. Use 'proton-ge' instead." >&2
        exit 1
        ;;
    "both")
        echo "Note: 'both' vendor changed to 'proton-ge' only (Valve doesn't provide pre-built binaries)" >&2
        VENDOR="proton-ge"
        ;;
    *)
        echo "Error: Unknown vendor '$VENDOR'. Use 'proton-ge' only." >&2
        usage
        exit 1
        ;;
esac

case "$OUTPUT_FORMAT" in
    "urls"|"json"|"human"|"versions"|"build-args") ;;
    *)
        echo "Error: Unknown output format '$OUTPUT_FORMAT'" >&2
        usage
        exit 1
        ;;
esac

# Validate count is a number
if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [[ "$COUNT" -lt 1 ]]; then
    echo "Error: COUNT must be a positive integer" >&2
    exit 1
fi

# Main execution
main() {
    local cache_ge="$CACHE_DIR/releases-ge.json"
    local cache_valve="$CACHE_DIR/releases-valve.json"
    
    # Fetch data for Proton-GE only (Valve doesn't provide pre-built binaries)
    fetch_releases "$GITHUB_API_GE" "$cache_ge" "Proton-GE"
    
    # Output results (Proton-GE only)
    case "$OUTPUT_FORMAT" in
        "human")
            output_human_header "proton-ge" "$COUNT"
            process_vendor_releases "proton-ge" "human" "$COUNT" "$cache_ge"
            ;;
        *)
            process_vendor_releases "proton-ge" "$OUTPUT_FORMAT" "$COUNT" "$cache_ge"
            ;;
    esac
}

# Run main function
main "$@"
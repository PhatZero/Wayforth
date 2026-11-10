#!/usr/bin/env bash
set -euo pipefail

: "${CURSEFORGE_TOKEN:?Set the CURSEFORGE_TOKEN Actions secret}"
: "${CURSEFORGE_PROJECT_ID:?Set the CURSEFORGE_PROJECT_ID Actions variable}"
: "${CHANGELOG:?Enter release notes for the CurseForge upload}"
[[ $CURSEFORGE_PROJECT_ID =~ ^[1-9][0-9]*$ ]] || { echo 'Expected a numeric CurseForge project ID.' >&2; exit 1; }
[[ $# == 1 && -f $1 ]] || { echo 'Expected one built Forever ZIP.' >&2; exit 1; }

archive=$1
toc=$(unzip -p "$archive" WayForth/WayForth.toc | tr -d '\r')
interface=$(sed -n 's/^## Interface: //p' <<< "$toc")
version=$(sed -n 's/^## Version: //p' <<< "$toc")
[[ $interface == 16001 && $version == *-beta* ]] || { echo 'Expected a Forever 1.60.1 beta manifest.' >&2; exit 1; }

api=https://wow.curseforge.com/api
header="X-Api-Token: $CURSEFORGE_TOKEN"
versions=$(curl --fail --silent --show-error --header "$header" "$api/game/versions")
version_id=$(jq -er '[.[] | select(.name == "1.60.1")] |
    if length == 1 and (.[0].id | type) == "number" then .[0].id
    else error("Expected exactly one CurseForge version ID for Forever 1.60.1") end' <<< "$versions")
metadata=$(jq -n --arg notes "$CHANGELOG" --arg version "$version" --argjson id "$version_id" \
    '{changelog: $notes, changelogType: "markdown", releaseType: "beta",
      displayName: ("WayForth " + $version + " (Forever)"), gameVersions: [$id]}')

response=$(curl --fail-with-body --silent --show-error --header "$header" \
    --form-string "metadata=$metadata" --form "file=@$archive;type=application/zip" \
    "$api/projects/$CURSEFORGE_PROJECT_ID/upload-file")
file_id=$(jq -er '.id | numbers | select(. > 0)' <<< "$response")
echo "Submitted WayForth $version for Forever. CurseForge file ID $file_id."

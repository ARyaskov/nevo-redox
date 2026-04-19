#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_cmd make
fetch_upstream
prepare_overlay

echo "Building Redox minimal server image"
echo "Upstream tree: ${UPSTREAM_ROOT}"
echo "Artifact: ${ARTIFACT_ROOT}/harddrive.img"

make -C "${UPSTREAM_ROOT}" "${IMAGE_TARGET}"
copy_artifact "${IMAGE_TARGET}" "harddrive.img"

echo
echo "Build finished."
echo "Image: ${ARTIFACT_ROOT}/harddrive.img"

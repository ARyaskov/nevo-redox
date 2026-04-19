#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_cmd make
fetch_upstream
prepare_overlay

echo "Building Redox minimal live ISO"
echo "Upstream tree: ${UPSTREAM_ROOT}"
echo "Artifact: ${ARTIFACT_ROOT}/redox-live.iso"

make -C "${UPSTREAM_ROOT}" "${ISO_TARGET}"
copy_artifact "${ISO_TARGET}" "redox-live.iso"

echo
echo "Build finished."
echo "ISO: ${ARTIFACT_ROOT}/redox-live.iso"

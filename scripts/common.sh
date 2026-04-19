#!/usr/bin/env bash
set -euo pipefail

STANDALONE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_ROOT="${STANDALONE_ROOT}/.upstream/redox"
ARTIFACT_ROOT="${STANDALONE_ROOT}/artifacts"
PROFILE_SOURCE="${STANDALONE_ROOT}/config/x86_64/server-minimal-qemu.toml"
PROFILE_DEST_REL="config/x86_64/server-minimal-qemu.toml"
CONFIG_NAME="server-minimal-qemu"
IMAGE_TARGET="build/x86_64/server-minimal-qemu/harddrive.img"
ISO_TARGET="build/x86_64/server-minimal-qemu/redox-live.iso"

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "error: required command not found: $1" >&2
        exit 1
    fi
}

ensure_podman_ready() {
    require_cmd podman
    case "$(uname -s)" in
        Darwin)
            if ! podman info >/dev/null 2>&1; then
                echo "error: podman is installed but not ready. Run: podman machine start" >&2
                exit 1
            fi
            ;;
        Linux)
            :
            ;;
        *)
            echo "error: unsupported host OS: $(uname -s)" >&2
            exit 1
            ;;
    esac
}

fetch_upstream() {
    require_cmd git
    ensure_podman_ready

    mkdir -p "${STANDALONE_ROOT}/.upstream"
    if [[ ! -d "${UPSTREAM_ROOT}/.git" ]]; then
        git clone --depth 1 https://gitlab.redox-os.org/redox-os/redox.git "${UPSTREAM_ROOT}"
    else
        git -C "${UPSTREAM_ROOT}" fetch --depth 1 origin HEAD
        git -C "${UPSTREAM_ROOT}" reset --hard FETCH_HEAD
        git -C "${UPSTREAM_ROOT}" clean -fdx
    fi
}

prepare_overlay() {
    mkdir -p "${UPSTREAM_ROOT}/config/x86_64"
    cp "${PROFILE_SOURCE}" "${UPSTREAM_ROOT}/${PROFILE_DEST_REL}"

    cat > "${UPSTREAM_ROOT}/.config" <<EOF
ARCH=x86_64
CONFIG_NAME=${CONFIG_NAME}
FILESYSTEM_CONFIG=${PROFILE_DEST_REL}

QEMU_MEM=${QEMU_MEM:-256}
QEMU_SMP=${QEMU_SMP:-1}
net=${QEMU_NET:-virtio}
disk=${QEMU_DISK:-virtio}
audio=no
gpu=no

CI=1
SCCACHE_BUILD=0
EOF
}

copy_artifact() {
    local source_rel="$1"
    local dest_name="$2"
    mkdir -p "${ARTIFACT_ROOT}"
    cp "${UPSTREAM_ROOT}/${source_rel}" "${ARTIFACT_ROOT}/${dest_name}"
}

find_firmware() {
    local candidates=(
        "/usr/share/ovmf/OVMF.fd"
        "/usr/share/OVMF/OVMF_CODE.fd"
        "/usr/share/qemu/edk2-x86_64-code.fd"
        "/opt/homebrew/opt/qemu/share/qemu/edk2s-x86_64-code.fd"
    )
    local path
    for path in "${candidates[@]}"; do
        if [[ -f "${path}" ]]; then
            printf '%s\n' "${path}"
            return 0
        fi
    done
    return 1
}

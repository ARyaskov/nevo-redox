#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

require_cmd qemu-system-x86_64

DISK_IMAGE="${ARTIFACT_ROOT}/harddrive.img"
PCAP_FILE="${ARTIFACT_ROOT}/network.pcap"

if [[ ! -f "${DISK_IMAGE}" ]]; then
    echo "error: image not found: ${DISK_IMAGE}" >&2
    echo "build it first with ./scripts/build-image.sh" >&2
    exit 1
fi

FIRMWARE_PATH="${OVMF_PATH:-}"
if [[ -z "${FIRMWARE_PATH}" ]]; then
    if ! FIRMWARE_PATH="$(find_firmware)"; then
        echo "error: could not find OVMF firmware. Set OVMF_PATH=/absolute/path/to/OVMF.fd" >&2
        exit 1
    fi
fi

QEMU_ACCEL_ARGS=()
case "${QEMU_ACCEL:-auto}" in
    auto)
        case "$(uname -s)" in
            Linux)
                if [[ -r /dev/kvm && -w /dev/kvm ]]; then
                    QEMU_ACCEL_ARGS=(-enable-kvm -cpu host)
                else
                    QEMU_ACCEL_ARGS=(-cpu max)
                fi
                ;;
            Darwin)
                QEMU_ACCEL_ARGS=(-accel hvf -cpu max)
                ;;
            *)
                QEMU_ACCEL_ARGS=(-cpu max)
                ;;
        esac
        ;;
    none)
        QEMU_ACCEL_ARGS=(-cpu max)
        ;;
    kvm)
        QEMU_ACCEL_ARGS=(-enable-kvm -cpu host)
        ;;
    hvf)
        QEMU_ACCEL_ARGS=(-accel hvf -cpu max)
        ;;
    *)
        echo "error: unsupported QEMU_ACCEL value: ${QEMU_ACCEL}" >&2
        exit 1
        ;;
esac

mkdir -p "${ARTIFACT_ROOT}"

exec qemu-system-x86_64 \
    -d guest_errors \
    -name RedoxOS \
    -smp "${QEMU_SMP:-1}" \
    -m "${QEMU_MEM:-256}" \
    -chardev stdio,id=debug,signal=off,mux=on \
    -serial chardev:debug \
    -mon chardev=debug \
    -machine q35 \
    "${QEMU_ACCEL_ARGS[@]}" \
    -bios "${FIRMWARE_PATH}" \
    -device virtio-net,netdev=net0 \
    -netdev "user,id=net0,hostfwd=tcp::8022-:22,hostfwd=tcp::8080-:8080,hostfwd=tcp::8081-:8081,hostfwd=tcp::8082-:8082,hostfwd=tcp::8083-:8083" \
    -object "filter-dump,id=f1,netdev=net0,file=${PCAP_FILE}" \
    -nographic \
    -vga none \
    -drive "file=${DISK_IMAGE},format=raw,if=virtio"

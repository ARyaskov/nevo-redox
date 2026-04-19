# Redox Minimal Server Overlay Repository

This directory is a standalone overlay repository layout.

It is designed for a separate Git repository that tracks only:

- the custom Redox filesystem profile
- the build and run scripts
- the documentation
- the local `.gitignore`

It does **not** require committing the full upstream Redox build system.
Instead, the scripts clone upstream Redox into a local ignored directory and build from there.

Everything downloaded or built by the scripts stays ignored:

- `.upstream/`
- `artifacts/`

## Distribution Goals

This profile is a minimal headless Redox distribution for `x86_64` with:

- no GUI stack
- UEFI boot support
- low-memory QEMU testing at `256 MiB`
- enough base tooling to log in and run a custom Rust server
- TCP networking through QEMU user-mode port forwarding
- a live ISO path for booting on real `x86_64` hardware

## Package Set

The image includes:

- `base`
- `base-initfs`
- `bootloader`
- `ca-certificates`
- `coreutils`
- `curl`
- `diffutils`
- `extrautils`
- `findutils`
- `gawk`
- `ion`
- `kernel`
- `libgcc`
- `libstdcxx`
- `netdb`
- `netutils`
- `nano`
- `openssl3`
- `pkgutils`
- `relibc`
- `rsync`
- `sed`
- `userutils`
- `uutils`
- `vim`
- `wget`

## Important Commands In Guest

### Shell and login

- `ion`
- `getty`
- `login`
- `sudo`
- `su`
- `passwd`

### File utilities

- `ls`
- `cp`
- `mv`
- `rm`
- `mkdir`
- `rmdir`
- `ln`
- `cat`
- `pwd`
- `chmod`
- `touch`
- `stat`
- `realpath`
- `readlink`
- `find`
- `sed`
- `awk`
- `diff`
- `cmp`
- `rsync`

### Networking

- `curl`
- `wget`
- `ifconfig`
- `dhcpd`
- `dns`
- `nc`
- `ping`

### Package management

- `pkg`

### Extra utilities

- `grep`
- `less`
- `nano`
- `vim`
- `tar`
- `unzip`
- `gzip`
- `gunzip`
- `watch`
- `dmesg`

### TLS and certificates

- `openssl`

## Host Requirements

### Build

- `git`
- `make`
- `podman`

### Run

- `qemu-system-x86_64`
- OVMF firmware

The run script checks common firmware paths automatically and also supports `OVMF_PATH=/absolute/path/to/OVMF.fd`.

## Supported Host Environments

- WSL2 with Ubuntu
- native Ubuntu/Linux
- macOS with Podman

Notes:

- on macOS, start Podman first with `podman machine start`
- on WSL2, `KVM` is usually unavailable, so the run script falls back to software emulation
- the run script uses `-cpu host` with KVM and `-cpu max` as the software fallback

## Repository Layout

```text
.
├── .gitignore
├── README.md
├── config/
│   └── x86_64/
│       └── server-minimal-qemu.toml
└── scripts/
    ├── common.sh
    ├── build-image.sh
    ├── build-live-iso.sh
    └── run-qemu.sh
```

## Build The Disk Image

From the standalone repository root:

```bash
./scripts/build-image.sh
```

Result:

- `artifacts/harddrive.img`

What happens:

1. upstream Redox is cloned into `.upstream/redox`
2. the custom profile is copied into the upstream tree
3. a deterministic `.config` is generated inside the upstream tree
4. the Redox image is built
5. the final image is copied into `artifacts/`

## Build The Live ISO

From the standalone repository root:

```bash
./scripts/build-live-iso.sh
```

Result:

- `artifacts/redox-live.iso`

This ISO is intended for UEFI boot on real `x86_64` hardware.

## Run In QEMU

From the standalone repository root:

```bash
./scripts/run-qemu.sh
```

Defaults:

- `256 MiB` RAM
- `1` vCPU
- `virtio-net`
- user-mode networking
- TCP port forwarding
- headless console

Forwarded host ports:

- `8022 -> 22`
- `8080 -> 8080`
- `8081 -> 8081`
- `8082 -> 8082`
- `8083 -> 8083`

Useful overrides:

```bash
QEMU_MEM=512 ./scripts/run-qemu.sh
QEMU_SMP=2 ./scripts/run-qemu.sh
QEMU_ACCEL=none ./scripts/run-qemu.sh
OVMF_PATH=/path/to/OVMF.fd ./scripts/run-qemu.sh
```

`QEMU_ACCEL` values:

- `auto`
- `none`
- `kvm`
- `hvf`

## Default Login

- `root` / `password`
- `user` / unset password

Default shell:

- `/usr/bin/ion`

## Recommended Network Test

Inside Redox:

```bash
nc -l 0.0.0.0:8080
```

On the host:

```bash
printf 'test\n' | nc 127.0.0.1 8080
```

If your server binds to `0.0.0.0:8080` inside Redox, access it from the host at:

```bash
http://127.0.0.1:8080
```

## Real Hardware Notes

- prefer UEFI boot on `x86_64`
- test the live ISO in QEMU before writing it to USB
- Redox is still under active development, so hardware support varies by device
- for server workloads, verify networking and storage behavior on target hardware before relying on it

## Upstream Source

The scripts fetch upstream Redox from:

- <https://gitlab.redox-os.org/redox-os/redox.git>

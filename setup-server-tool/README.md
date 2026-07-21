# Setup Server Tool

`setup-server-tool` is a modular Bash CLI for repeatable Linux server
bootstrapping. It supports dry runs, non-interactive execution, retries, logs,
preflight checks, configuration backups, and an installation manifest.

## Supported systems

| Operating system | Package manager | Tested by fixture |
| --- | --- | --- |
| Ubuntu 20.04/22.04/24.04 | apt | Yes |
| Debian 12 | apt | Yes |
| Amazon Linux 2 | yum | Yes |
| Amazon Linux 2023 | dnf | Yes |
| RHEL, Rocky, AlmaLinux, CentOS, Fedora | dnf/yum | Detection only; validate on the target release |

Only x86_64 and arm64 architectures are supported.

## Features

- Docker Engine and pinned Docker Compose with checksum validation.
- Pinned AWS CLI v2 with PGP signature verification.
- Multiple Node.js versions via a checksum-verified NVM installation.
- Automatic `test-ses` workspace deployment into `~/infra/test-ses` for the
  detected target user, with npm dependencies installed in place.
- App deployment workspace templates for `~/infra` and source directories
  under `~/sources`, with idempotent copy behavior.
- Managed runtime artifacts, manifests, logs, compose files, and data
  directories live under `~/infra` for the selected target user.
- Native Nginx or a pinned Docker Nginx deployment.
- Pinned Nginx Proxy Manager with an explicit admin bind address requirement.
- Certbot issuance, renewal timer/cron, dry-run renewal test, and reload hook.
- Uninstall flows for every installable module, with conservative cleanup for
  OS-level baseline and security changes.
- Baseline profile: timezone, NTP, optional swap, hostname, and log rotation.
- Security profile: admin user/key, SSH hardening, firewall, fail2ban, and
  automatic security updates.
- Service, container, port, local HTTP, SELinux, tool-version, and manifest
  health checks.
- Idempotent base-package checks and scoped handling for APT repository
  release metadata changes.
- Feature detection for older curl releases, including Ubuntu 20.04's curl
  without `--retry-all-errors`.

## Quick start

```bash
cd setup-server-tool
chmod +x setup.sh modules/install/*.sh modules/utils/*.sh tests/run.sh
./setup.sh --dry-run --all
./setup.sh --yes --target-user ubuntu --all
```

Options can appear in any order:

```bash
./setup.sh --node-versions "20 22" --target-user ubuntu --yes nodejs
./setup.sh --yes test-ses
./setup.sh --yes deploy-workspace
./setup.sh --yes --nginx-mode docker nginx
./setup.sh --yes --web
./setup.sh --yes --security
./setup.sh --yes --uninstall nginx-proxy-manager
./setup.sh --health
```

The `--web` profile installs Docker and Nginx Proxy Manager. It deliberately
does not install standalone Certbot because Nginx Proxy Manager owns its own
Let's Encrypt lifecycle.

`docker` access is granted by adding the target user to the `docker` group.
The first shell after installation still needs a re-login or `newgrp docker`
before `docker` works without `sudo`.

## Execution controls

| Option | Behavior |
| --- | --- |
| `--dry-run` | Prints mutating commands without running them. |
| `--yes` | Approves firewall and other explicit confirmations. |
| `--non-interactive` | Disables prompts; combine with `--yes` for security changes. |
| `--force` | Refreshes pinned installers or managed configuration. |
| `--target-user USER` | Selects the NVM owner and Docker group member. |
| `--log-file PATH` | Overrides the execution log. |
| `--manifest-file PATH` | Overrides the installation manifest. |
| `--uninstall` | Runs uninstall scripts for the selected profile or modules. |

The default manifest is `~/infra/setup-server-tool/state/manifest.tsv`. The
default log is `~/infra/setup-server-tool/state/setup.log`.

When an APT repository changes signed release metadata such as `Label`, the
tool reports the changed field and asks for confirmation. A retry allows only
that field, for example `--allow-releaseinfo-change-label`; unrelated APT
errors still stop the run.

## Configuration

Review and source the example configuration before a non-interactive rollout:

```bash
source ./config.example.env
./setup.sh --dry-run --security
./setup.sh --yes --non-interactive --security
```

Important variables:

| Variable | Default | Description |
| --- | --- | --- |
| `AWS_CLI_VERSION` | `2.36.4` | Versioned AWS CLI installer. |
| `DOCKER_COMPOSE_VERSION` | `v5.1.4` | Compose fallback binary release. |
| `NVM_VERSION` | `v0.40.6` | Checksum-pinned NVM release. |
| `NODE_VERSIONS` | `22` | Space-separated Node.js versions. |
| `INFRA_ROOT` | `~/infra` | Root directory for managed artifacts owned by the target user. |
| `SOURCES_ROOT` | `~/sources` | Root directory for application source checkouts. |
| `TEST_SES_SOURCE_DIR` | `../test-ses` | Source directory copied into `~/infra/test-ses`. |
| `TEST_SES_TARGET_DIR` | `~/infra/test-ses` | Deployment path for the target user's SES test workspace. |
| `NGINX_MODE` | `apt` | `apt` or `docker`. |
| `NPM_ADMIN_BIND` | empty | Required bind address for the NPM admin listener. |
| `NPM_ADMIN_PORT` | `81` | NPM admin listener port. |
| `CERTBOT_DOMAINS` | empty | Space-separated native Nginx certificate domains. |
| `CERTBOT_EMAIL` | empty | Required when issuing a certificate. |
| `SERVER_TIMEZONE` | `UTC` | Baseline system timezone. |
| `BASELINE_SWAP_SIZE_GB` | `0` | Swap size; zero leaves swap unchanged. |
| `ADMIN_USER` | empty | Optional sudo administrator to create. |
| `ADMIN_SSH_PUBLIC_KEY` | empty | Public key installed for `ADMIN_USER`. |
| `SSH_DISABLE_PASSWORD_AUTH` | `true` | Takes effect only after an authorized key exists. |

SSH configuration is validated with `sshd -t` before reload. Password login
is kept enabled when the selected administrator has no `authorized_keys`, so
the profile does not lock out the active operator. When `SSH_PORT` is not set,
the profile uses the server port from `SSH_CONNECTION` before falling back to
port 22.

## Certbot

For native Nginx:

```bash
CERTBOT_DOMAINS="example.com www.example.com" \
CERTBOT_EMAIL="admin@example.com" \
./setup.sh --yes certbot
```

The module enables a systemd timer when available, otherwise installs a cron
job. Existing certificates are checked with `certbot renew --dry-run`.

## Test SES

```bash
./setup.sh --yes --target-user ubuntu test-ses
```

The module copies the local [`test-ses`](../test-ses) workspace into the
target user's `~/infra/test-ses`. When `--target-user` is omitted, the tool
resolves the default OS user such as `ubuntu` or `ec2-user` from the active
session and installs there.

## App deployment workspace

```bash
./setup.sh --yes --target-user ubuntu deploy-workspace
```

The module copies the templates from `templates/deploy-workspace` without
overwriting existing files. It creates `~/infra/Makefile`, environment files
under `~/infra/env`, app Compose examples, and empty backend/frontend source
directories under `~/sources`. Nginx Proxy Manager remains owned by its own
module at `~/infra/nginx-proxy-manager`.

The generated Makefile resolves paths from its own location, so commands such
as `make -C ~/infra be` behave the same from any working directory. Project
specific paths, Compose service names, and the backend deploy command live in
`~/infra/env/deploy.env`.

## Uninstall

```bash
./setup.sh --yes --uninstall docker
./setup.sh --yes --uninstall nginx-proxy-manager test-ses
./setup.sh --yes --uninstall --all
```

Package-managed binaries such as Docker Engine, AWS CLI, native Nginx, and
Certbot are removed with the OS package manager or vendor uninstallers.
Managed artifacts under `~/infra` are deleted by the module uninstallers.
`baseline` and `security` uninstallers remove only the files and services that
the tool manages directly; they do not blindly revert hostname, timezone,
firewall rules, or administrative users.

## Validation

```bash
./tests/run.sh
./tests/os-matrix.sh
./setup.sh --preflight
./setup.sh --health
```

The fast tests cover OS detection, unsupported releases, argument order,
conflicting profiles, pinned images, remote-script policy, Bash syntax, AWS
dry-run cleanup, and the embedded AWS signing-key fingerprint. The Docker
matrix executes detection inside real Ubuntu 20.04/24.04, Debian, Amazon Linux
2, and Amazon Linux 2023 images. Run the full dry-run on every target image
before the first production rollout.

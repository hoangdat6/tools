#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"
LIB_DIR="$SCRIPT_DIR/lib"

# shellcheck disable=SC1091
source "$LIB_DIR/common.sh"

NODE_VERSIONS="${NODE_VERSIONS:-22}"
NGINX_MODE="${NGINX_MODE:-apt}"
ACTION=""
MODULE_QUEUE=()
MODULE_MODE="install"

export_runtime() {
    export SETUP_TOOL_VERSION SETUP_DRY_RUN SETUP_ASSUME_YES SETUP_NON_INTERACTIVE
    export SETUP_FORCE SETUP_RETRY_COUNT SETUP_LOG_FILE SETUP_MANIFEST_FILE TARGET_USER
    export NODE_VERSIONS NGINX_MODE MODULE_MODE INFRA_ROOT SETUP_STATE_DIR TARGET_HOME
}

run_module() {
    local module="$1" module_path=""
    if [ "$MODULE_MODE" = "install" ] && [ -f "$MODULES_DIR/install/$module.sh" ]; then
        module_path="$MODULES_DIR/install/$module.sh"
    elif [ "$MODULE_MODE" = "uninstall" ] && [ -f "$MODULES_DIR/uninstall/$module.sh" ]; then
        module_path="$MODULES_DIR/uninstall/$module.sh"
    elif [ "$MODULE_MODE" = "install" ] && [ -f "$MODULES_DIR/utils/$module.sh" ]; then
        module_path="$MODULES_DIR/utils/$module.sh"
    fi
    [ -n "$module_path" ] || fail "Module not found: $module"

    export_runtime
    print_info "Running ${MODULE_MODE} module: $module"
    bash "$module_path"
    print_success "${MODULE_MODE^} module $module completed."
}

install_all() {
    run_module preflight
    run_module deploy-workspace
    run_module docker
    run_module aws-cli
    run_module nodejs
    run_module test-ses
    run_module nginx
    run_module certbot
}

install_web_stack() {
    run_module preflight
    run_module docker
    run_module nginx-proxy-manager
}

install_security_profile() {
    run_module preflight
    run_module baseline
    run_module security
}

uninstall_all() {
    run_module certbot
    run_module nginx-proxy-manager
    run_module nginx
    run_module test-ses
    run_module deploy-workspace
    run_module nodejs
    run_module aws-cli
    run_module docker
    run_module security
    run_module baseline
}

uninstall_web_stack() {
    run_module nginx-proxy-manager
    run_module nginx
    run_module docker
}

uninstall_security_profile() {
    run_module security
    run_module baseline
}

show_menu() {
    printf '%b\n' "$YELLOW"
    printf '%s\n' '┌────────────────────────────────────────────────────────────────────┐'
    printf '%s\n' '│                         SERVER SETUP MENU                         │'
    printf '%s\n' '├────────────────────────────────────────────────────────────────────┤'
    printf '%s\n' '│  [1] Docker + Docker Compose                                      │'
    printf '%s\n' '│  [2] AWS CLI v2                                                   │'
    printf '%s\n' '│  [3] Node.js via NVM                                              │'
    printf '%s\n' '│  [4] Nginx native package                                         │'
    printf '%s\n' '│  [5] Nginx Docker container                                       │'
    printf '%s\n' '│  [6] Nginx Proxy Manager                                          │'
    printf '%s\n' '│  [7] Certbot + auto renew                                         │'
    printf '%s\n' '│  [8] Baseline + security profile                                  │'
    printf '%s\n' '│  [9] Test SES workspace                                           │'
    printf '%s\n' '│  [10] App deploy workspace                                        │'
    printf '%s\n' '├────────────────────────────────────────────────────────────────────┤'
    printf '%s\n' '│  [A] Install core stack                                           │'
    printf '%s\n' '│  [W] Install web proxy stack                                      │'
    printf '%s\n' '│  [U] Uninstall modules/profile                                    │'
    printf '%s\n' '│  [P] Preflight check                                              │'
    printf '%s\n' '│  [H] Health check                                                 │'
    printf '%s\n' '│  [Q] Quit                                                         │'
    printf '%s\n' '└────────────────────────────────────────────────────────────────────┘'
    printf '%b\n' "$NC"
}

show_help() {
    cat <<'EOF'
Usage: ./setup.sh [OPTIONS] [module ...]

Profiles:
  --all, -a                    Deploy workspace, Docker, AWS CLI, Node.js, Test SES, Nginx, Certbot
  --web, -w                    Docker and Nginx Proxy Manager
  --security, -s               Baseline and security hardening profile
  --uninstall, -u              Uninstall the selected profile or modules

Options:
  --dry-run                    Print operations without changing the system
  --yes, -y                    Approve prompts
  --non-interactive            Never prompt; risky actions also require --yes
  --force                      Reinstall or recreate managed components
  --target-user USER           User that owns NVM and receives Docker access
  --node-versions "20 22 24"   Node.js versions installed with NVM
  --nginx-mode apt|docker      Nginx deployment mode
  --log-file PATH              Override execution log path
  --manifest-file PATH         Override installed-component manifest path
  --health, -c                 Run health checks
  --preflight, -p              Run preflight checks
  --version, -v                Print tool version
  --help, -h                   Show this help

Modules:
  preflight deploy-workspace docker aws-cli nodejs test-ses nginx nginx-proxy-manager certbot
  baseline security health-check

Examples:
  ./setup.sh --dry-run --all
  ./setup.sh --yes --target-user ubuntu --node-versions "20 22" nodejs
  ./setup.sh --nginx-mode docker nginx
  ./setup.sh --yes --security
  ./setup.sh --yes --uninstall docker nginx-proxy-manager
EOF
}

set_action() {
    [ -z "$ACTION" ] || fail "Only one profile/action can be selected."
    ACTION="$1"
}

parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --all|-a) set_action all; shift ;;
            --web|-w) set_action web; shift ;;
            --security|-s) set_action security; shift ;;
            --uninstall|-u) MODULE_MODE=uninstall; shift ;;
            --health|-c) set_action health; shift ;;
            --preflight|-p) set_action preflight; shift ;;
            --dry-run) SETUP_DRY_RUN=true; shift ;;
            --yes|-y) SETUP_ASSUME_YES=true; shift ;;
            --non-interactive) SETUP_NON_INTERACTIVE=true; shift ;;
            --force) SETUP_FORCE=true; shift ;;
            --target-user)
                [ -n "${2:-}" ] || fail "--target-user requires a value"
                TARGET_USER="$2"; shift 2 ;;
            --node-versions)
                [ -n "${2:-}" ] || fail "--node-versions requires a value"
                NODE_VERSIONS="$2"; shift 2 ;;
            --nginx-mode)
                [ -n "${2:-}" ] || fail "--nginx-mode requires apt or docker"
                NGINX_MODE="$2"; shift 2 ;;
            --log-file)
                [ -n "${2:-}" ] || fail "--log-file requires a path"
                SETUP_LOG_FILE="$2"; shift 2 ;;
            --manifest-file)
                [ -n "${2:-}" ] || fail "--manifest-file requires a path"
                SETUP_MANIFEST_FILE="$2"; shift 2 ;;
            --version|-v) printf 'setup-server-tool %s\n' "$SETUP_TOOL_VERSION"; exit 0 ;;
            --help|-h) show_help; exit 0 ;;
            --*) fail "Unknown option: $1" ;;
            *) MODULE_QUEUE+=("$1"); shift ;;
        esac
    done
}

execute_request() {
    if [ -z "$ACTION" ] && [ "${#MODULE_QUEUE[@]}" -eq 1 ]; then
        case "${MODULE_QUEUE[0]}" in
            all|web|security)
                ACTION="${MODULE_QUEUE[0]}"
                MODULE_QUEUE=()
                ;;
        esac
    fi
    export_runtime
    case "$ACTION" in
        all)
            [ "$MODULE_MODE" = "install" ] && install_all || uninstall_all
            ;;
        web)
            [ "$MODULE_MODE" = "install" ] && install_web_stack || uninstall_web_stack
            ;;
        security)
            [ "$MODULE_MODE" = "install" ] && install_security_profile || uninstall_security_profile
            ;;
        health)
            [ "$MODULE_MODE" = "install" ] || fail "Health checks do not support uninstall."
            run_module health-check
            ;;
        preflight)
            [ "$MODULE_MODE" = "install" ] || fail "Preflight checks do not support uninstall."
            run_module preflight
            ;;
        '')
            if [ "${#MODULE_QUEUE[@]}" -gt 0 ]; then
                local module
                for module in "${MODULE_QUEUE[@]}"; do run_module "$module"; done
            else
                return 1
            fi
            ;;
    esac
}

interactive_menu() {
    while true; do
        show_menu
        read -r -p "Select an option: " choice
        printf '\n'
        case "$choice" in
            1) run_module docker ;;
            2) run_module aws-cli ;;
            3)
                read -r -p "Node versions to install [22]: " versions
                NODE_VERSIONS="${versions:-22}"
                run_module nodejs
                ;;
            4) NGINX_MODE=apt run_module nginx ;;
            5) NGINX_MODE=docker run_module nginx ;;
            6) run_module nginx-proxy-manager ;;
            7) run_module certbot ;;
            8) install_security_profile ;;
            9) run_module test-ses ;;
            10) run_module deploy-workspace ;;
            [Aa]) install_all ;;
            [Ww]) install_web_stack ;;
            [Uu])
                read -r -p "Enter profile or modules to uninstall: " uninstall_targets
                [ -n "$uninstall_targets" ] || { print_error "No uninstall target provided."; continue; }
                MODULE_MODE=uninstall
                ACTION=""
                MODULE_QUEUE=()
                case "$uninstall_targets" in
                    all|web|security) ACTION="$uninstall_targets" ;;
                    *)
                        # shellcheck disable=SC2206
                        MODULE_QUEUE=($uninstall_targets)
                        ;;
                esac
                execute_request
                MODULE_MODE=install
                ACTION=""
                MODULE_QUEUE=()
                ;;
            [Pp]) run_module preflight ;;
            [Hh]) run_module health-check ;;
            [Qq]) exit 0 ;;
            *) print_error "Invalid option: $choice" ;;
        esac
        printf '\n'
        read -r -p "Press Enter to continue..."
        clear || true
    done
}

main() {
    parse_args "$@"
    print_header
    if execute_request; then
        return 0
    fi
    is_true "$SETUP_NON_INTERACTIVE" && fail "No action supplied in non-interactive mode."
    interactive_menu
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi

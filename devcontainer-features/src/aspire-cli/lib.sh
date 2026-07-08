#!/usr/bin/env bash

ASPIRE_CLI_BIN="${ASPIRE_CLI_BIN:-/usr/local/bin/aspire}"
ASPIRE_DOTNET_TOOL_PATH="${ASPIRE_DOTNET_TOOL_PATH:-/usr/local/share/aspire-cli/dotnet-tools}"

err() {
    echo "(!) $*" >&2
}

requireRoot() {
    if [ "$(id -u)" -ne 0 ]; then
        err "Script must be run as root. Use sudo, su, or add 'USER root' to your Dockerfile before running this script."
        exit 1
    fi
}

commandExists() {
    command -v "$1" >/dev/null 2>&1
}

exitIfAspireCliInstalled() {
    if commandExists aspire; then
        echo "Aspire CLI is already installed. Skipping."
        exit 0
    fi
}

linkExecutable() {
    local source_path="$1"
    local target_path="$2"

    if [ ! -x "${source_path}" ]; then
        err "Expected executable was not created: ${source_path}"
        exit 1
    fi

    install -d "$(dirname "${target_path}")"

    if [ "${source_path}" = "${target_path}" ]; then
        return
    fi

    ln -sf "${source_path}" "${target_path}"
}

hasMise() {
    commandExists mise
}

hasNuget() {
    commandExists dotnet
}

hasNpm() {
    commandExists npm
}

selectInstaller() {
    if hasMise; then
        echo mise
        return
    fi

    if hasNuget; then
        echo nuget
        return
    fi

    if hasNpm; then
        echo npm
        return
    fi

    err "Aspire CLI requires one of these package managers to already be installed: mise, dotnet CLI, or npm."
    exit 1
}

installWithMise() {
    local install_root

    mise use -g aspire
    install_root="$(mise where aspire 2>/dev/null || true)"

    if [ -z "${install_root}" ]; then
        err "mise installed Aspire CLI, but 'mise where aspire' did not return an install path."
        exit 1
    fi

    linkExecutable "${install_root}/bin/aspire" "${ASPIRE_CLI_BIN}"
}

installWithNuget() {
    install -d "${ASPIRE_DOTNET_TOOL_PATH}"

    if [ -x "${ASPIRE_DOTNET_TOOL_PATH}/aspire" ]; then
        dotnet tool update --tool-path "${ASPIRE_DOTNET_TOOL_PATH}" Aspire.Cli
    else
        dotnet tool install --tool-path "${ASPIRE_DOTNET_TOOL_PATH}" Aspire.Cli
    fi

    chmod -R a+rX "${ASPIRE_DOTNET_TOOL_PATH}"
    linkExecutable "${ASPIRE_DOTNET_TOOL_PATH}/aspire" "${ASPIRE_CLI_BIN}"
}

installWithNpm() {
    local npm_prefix

    npm install -g @microsoft/aspire-cli
    npm_prefix="$(npm prefix -g)"
    linkExecutable "${npm_prefix}/bin/aspire" "${ASPIRE_CLI_BIN}"
}

installAspireCli() {
    case "$1" in
        mise)
            installWithMise
            ;;
        nuget)
            installWithNuget
            ;;
        npm)
            installWithNpm
            ;;
        *)
            err "Unsupported Aspire CLI installer: $1"
            exit 1
            ;;
    esac
}

verifyAspireCli() {
    if ! commandExists aspire; then
        err "Aspire CLI is not on PATH after installation."
        exit 1
    fi
}

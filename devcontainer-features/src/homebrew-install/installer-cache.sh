#!/usr/bin/env bash

homebrewInstallerCacheValidateMode() {
    case "${1:-auto}" in
        auto|refresh|offline)
            return 0
            ;;
        *)
            err "Unsupported Homebrew installer cache mode: ${1:-}"
            exit 1
            ;;
    esac
}

homebrewInstallerCacheSignatureFromHeaders() {
    awk '
        {
            line = $0
            sub("\r$", "", line)

            if (tolower(line) ~ /^etag:/) {
                sub("^[^:]*:[[:space:]]*", "", line)
                etag = line
            }

            if (tolower(line) ~ /^last-modified:/) {
                sub("^[^:]*:[[:space:]]*", "", line)
                last_modified = line
            }
        }
        END {
            printf "etag=%s\nlast-modified=%s\n", etag, last_modified
        }
    '
}

homebrewInstallerCacheFetchHeaders() {
    curl -fsSLI --retry 5 "${1}"
}

homebrewInstallerCacheAcquireLock() {
    local cache_file="$1"

    homebrew_installer_cache_lock_dir="${cache_file}.lock"
    while ! mkdir "${homebrew_installer_cache_lock_dir}" 2>/dev/null; do
        sleep 1
    done
}

homebrewInstallerCacheReleaseLock() {
    if [ -n "${homebrew_installer_cache_lock_dir:-}" ]; then
        rm -rf "${homebrew_installer_cache_lock_dir}"
        homebrew_installer_cache_lock_dir=""
    fi
}

downloadHomebrewInstaller() {
    local installer_url="$1"
    local cache_directory="$2"
    local cache_mode="${3:-auto}"
    local cache_file
    local cache_meta_file
    local remote_headers
    local remote_signature
    local local_signature
    local temp_file
    local temp_meta_file

    homebrewInstallerCacheValidateMode "${cache_mode}"

    cache_file="${cache_directory%/}/install.sh"
    cache_meta_file="${cache_file}.meta"

    install -d "${cache_directory}"
    homebrewInstallerCacheAcquireLock "${cache_file}"
    trap homebrewInstallerCacheReleaseLock EXIT INT TERM HUP

    if [ -f "${cache_file}" ]; then
        case "${cache_mode}" in
            offline)
                printf '%s\n' "${cache_file}"
                return
                ;;
            auto)
                if remote_headers="$(homebrewInstallerCacheFetchHeaders "${installer_url}" 2>/dev/null)"; then
                    remote_signature="$(printf '%s\n' "${remote_headers}" | homebrewInstallerCacheSignatureFromHeaders)"
                    if [ -f "${cache_meta_file}" ] && [ "$(cat "${cache_meta_file}")" = "${remote_signature}" ]; then
                        printf '%s\n' "${cache_file}"
                        return
                    fi

                    if [ ! -f "${cache_meta_file}" ]; then
                        printf '%s\n' "${cache_file}"
                        return
                    fi
                else
                    printf '%s\n' "${cache_file}"
                    return
                fi
                ;;
            refresh)
                ;;
        esac
    elif [ "${cache_mode}" = "offline" ]; then
        err "No cached Homebrew installer is available at ${cache_file}, and offline cache mode is enabled."
        exit 1
    fi

    temp_file="$(mktemp "${cache_file}.XXXXXX")"
    temp_meta_file="$(mktemp "${cache_meta_file}.XXXXXX")"

    if remote_headers="$(homebrewInstallerCacheFetchHeaders "${installer_url}" 2>/dev/null)"; then
        remote_signature="$(printf '%s\n' "${remote_headers}" | homebrewInstallerCacheSignatureFromHeaders)"
        printf '%s\n' "${remote_signature}" > "${temp_meta_file}"
    fi

    curl -fsSL --retry 5 "${installer_url}" -o "${temp_file}"
    chmod 0644 "${temp_file}"
    mv -f "${temp_file}" "${cache_file}"

    if [ -s "${temp_meta_file}" ]; then
        mv -f "${temp_meta_file}" "${cache_meta_file}"
    else
        rm -f "${temp_meta_file}"
    fi

    printf '%s\n' "${cache_file}"
}

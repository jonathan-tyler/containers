set shell := ["bash", "-euo", "pipefail", "-c"]

project_root := justfile_directory()
feature_root := env_var_or_default("FEATURE_PROJECT_DIR", project_root + "/devcontainer-features")
workspace_root := env_var_or_default("FEATURE_CI_WORKSPACE", env_var_or_default("TMPDIR", "/tmp") + "/feature-ci")
runtime_root := env_var_or_default("FEATURE_CI_RUNTIME_ROOT", "/tmp/feature-ci-runtime")
feature_project_root := workspace_root
package_output_root := workspace_root + "/package"
shim_dir := workspace_root + "/bin"
docker_config_dir := runtime_root + "/docker-config"
workflow_file := project_root + "/.github/workflows/test.yaml"
workflow_base_image := env_var_or_default("BASE_IMAGE", "registry.access.redhat.com/hi/core-runtime:latest-builder")
workflow_remote_user := env_var_or_default("REMOTE_USER", "root")
homebrew_ci_base_image := env_var_or_default("HOME_BREW_CI_BASE_IMAGE", "localhost/feature-ci/core-runtime:latest-homebrew")
homebrew_ci_base_containerfile := feature_root + "/test/homebrew-install/feature-ci-base/Containerfile"
homebrew_ci_redhat_cache_image := env_var_or_default("HOME_BREW_CI_REDHAT_CACHE_IMAGE", "localhost/feature-ci/homebrew-scenario-cache:redhat")
homebrew_ci_redhat_cache_containerfile := feature_root + "/test/homebrew-packages/feature-ci-base/redhat-cache/Containerfile"
homebrew_ci_ubuntu_cache_image := env_var_or_default("HOME_BREW_CI_UBUNTU_CACHE_IMAGE", "localhost/feature-ci/homebrew-scenario-cache:ubuntu")
homebrew_ci_ubuntu_cache_containerfile := feature_root + "/test/homebrew-packages/feature-ci-base/ubuntu-cache/Containerfile"
xdg_runtime_dir := env_var_or_default("XDG_RUNTIME_DIR", runtime_root + "/xdg")
podman_socket_path := xdg_runtime_dir + "/podman/podman.sock"
podman_service_log_file := workspace_root + "/podman-system-service.log"
act_runner_image := env_var_or_default("ACT_RUNNER_IMAGE", "ghcr.io/catthehacker/ubuntu:act-latest")
act_tmp_dir := workspace_root + "/tmp"
yt_dlp_test_image := env_var_or_default("YT_DLP_TEST_IMAGE", "localhost/yt-dlp:test")
yt_dlp_containerfile := project_root + "/images/yt-dlp/Containerfile"
feature_ci_env := "PATH=\"" + shim_dir + ":$PATH\" DOCKER_CONFIG=\"" + docker_config_dir + "\" FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true XDG_RUNTIME_DIR=\"" + xdg_runtime_dir + "\""
act_env := "DOCKER_HOST=\"unix://" + podman_socket_path + "\" " + feature_ci_env + " TMPDIR=\"" + act_tmp_dir + "\" TMP=\"" + act_tmp_dir + "\" TEMP=\"" + act_tmp_dir + "\""

default:
    @just --list

hooks:
    @git -C "{{project_root}}" config --local core.hooksPath ".githooks"
    @printf 'git hooks path set to %s\n' "{{project_root}}/.githooks"

bump-feature-version +args:
    @"{{project_root}}/scripts/bump-feature-version.sh" {{args}}

check-feature-version-bumps:
    @"{{project_root}}/scripts/check-feature-version-bumps.sh" --staged

test-yt-dlp:
    @command -v podman >/dev/null 2>&1 || { printf 'missing required tool: podman\n' >&2; exit 1; }
    @podman build --file "{{yt_dlp_containerfile}}" --tag "{{yt_dlp_test_image}}" "{{project_root}}"
    @podman run --rm "{{yt_dlp_test_image}}" --version

prepare:
    @"{{project_root}}/scripts/feature-ci-workspace.sh" --copy-feature-tree just prepare-run

prepare-run: check-feature-tools prepare-runtime
    @printf 'feature-ci workspace prepared at %s\n' "{{workspace_root}}"

ci:
    @"{{project_root}}/scripts/feature-ci-workspace.sh" just ci-run

ci-run: check-act-tools prepare-runtime
    @podman_service_pid=''; \
    if [ ! -S "{{podman_socket_path}}" ] || ! podman --url "unix://{{podman_socket_path}}" info >/dev/null 2>&1; then \
        rm -f "{{podman_socket_path}}"; \
        nohup podman system service --time=0 "unix://{{podman_socket_path}}" >"{{podman_service_log_file}}" 2>&1 & \
        podman_service_pid=$!; \
        trap 'if [ -n "$podman_service_pid" ]; then kill "$podman_service_pid" 2>/dev/null || true; fi' EXIT; \
        for _ in 1 2 3 4 5 6 7 8 9 10; do \
            if podman --url "unix://{{podman_socket_path}}" info >/dev/null 2>&1; then \
                break; \
            fi; \
            sleep 1; \
        done; \
        if ! podman --url "unix://{{podman_socket_path}}" info >/dev/null 2>&1; then \
            printf 'feature-ci: podman service did not become ready, see %s\n' "{{podman_service_log_file}}" >&2; \
            exit 1; \
        fi; \
    fi; \
    {{act_env}} act workflow_dispatch --bind --env TMPDIR="{{act_tmp_dir}}" --env TMP="{{act_tmp_dir}}" --env TEMP="{{act_tmp_dir}}" --workflows "{{workflow_file}}" -P ubuntu-latest="{{act_runner_image}}"

job job_name:
    @"{{project_root}}/scripts/feature-ci-workspace.sh" just job-run "{{job_name}}"

job-run job_name: check-act-tools prepare-runtime
    @podman_service_pid=''; \
    if [ ! -S "{{podman_socket_path}}" ] || ! podman --url "unix://{{podman_socket_path}}" info >/dev/null 2>&1; then \
        rm -f "{{podman_socket_path}}"; \
        nohup podman system service --time=0 "unix://{{podman_socket_path}}" >"{{podman_service_log_file}}" 2>&1 & \
        podman_service_pid=$!; \
        trap 'if [ -n "$podman_service_pid" ]; then kill "$podman_service_pid" 2>/dev/null || true; fi' EXIT; \
        for _ in 1 2 3 4 5 6 7 8 9 10; do \
            if podman --url "unix://{{podman_socket_path}}" info >/dev/null 2>&1; then \
                break; \
            fi; \
            sleep 1; \
        done; \
        if ! podman --url "unix://{{podman_socket_path}}" info >/dev/null 2>&1; then \
            printf 'feature-ci: podman service did not become ready, see %s\n' "{{podman_service_log_file}}" >&2; \
            exit 1; \
        fi; \
    fi; \
    {{act_env}} act workflow_dispatch --bind --env TMPDIR="{{act_tmp_dir}}" --env TMP="{{act_tmp_dir}}" --env TEMP="{{act_tmp_dir}}" --workflows "{{workflow_file}}" --job "{{job_name}}" -P ubuntu-latest="{{act_runner_image}}"

feature +features:
    @"{{project_root}}/scripts/feature-ci-workspace.sh" --copy-feature-tree --stamp-homebrew-base-image just feature-run {{features}}

feature-run +features: check-feature-tools prepare-runtime
    @base_image="{{workflow_base_image}}"; \
    if [[ " {{features}} " == *" homebrew-install "* || " {{features}} " == *" homebrew-packages "* || " {{features}} " == *" homebrew-packages-additional "* ]]; then \
        {{feature_ci_env}} docker build -f "{{homebrew_ci_base_containerfile}}" -t "{{homebrew_ci_base_image}}" "{{project_root}}"; \
    fi; \
    if [[ " {{features}} " == *" homebrew-packages "* || " {{features}} " == *" homebrew-packages-additional "* ]]; then \
        base_image="{{homebrew_ci_base_image}}"; \
        {{feature_ci_env}} docker build -f "{{homebrew_ci_redhat_cache_containerfile}}" -t "{{homebrew_ci_redhat_cache_image}}" "{{project_root}}"; \
        {{feature_ci_env}} docker build -f "{{homebrew_ci_ubuntu_cache_containerfile}}" -t "{{homebrew_ci_ubuntu_cache_image}}" "{{project_root}}"; \
    fi; \
    {{feature_ci_env}} devcontainer features test --project-folder "{{feature_root}}" --skip-autogenerated --skip-duplicated --base-image "$base_image" --remote-user "{{workflow_remote_user}}" -f {{features}}

podman-in-podman-smoke: check-feature-tools prepare-runtime
    {{feature_ci_env}} "{{feature_root}}/test/podman-in-podman/devcontainer-cli-smoke.sh"

publish-check:
    @"{{project_root}}/scripts/feature-ci-workspace.sh" --copy-feature-tree just publish-run

publish-run: check-feature-tools prepare-runtime
    @rm -rf "{{package_output_root}}"
    {{feature_ci_env}} devcontainer features package "{{feature_project_root}}/src" --output-folder "{{package_output_root}}" --force-clean-output-folder
    test -f "{{package_output_root}}/devcontainer-collection.json"

all:
    just ci
    just publish-check

[private]
check-feature-tools:
    @for tool in bash devcontainer jq podman; do \
        command -v "$tool" >/dev/null 2>&1 || { printf 'feature-ci: missing required tool: %s\n' "$tool" >&2; exit 1; }; \
    done

[private]
check-act-tools:
    @for tool in bash act podman; do \
        command -v "$tool" >/dev/null 2>&1 || { printf 'feature-ci: missing required tool: %s\n' "$tool" >&2; exit 1; }; \
    done

[private]
prepare-runtime:
    @mkdir -p "{{shim_dir}}" "{{docker_config_dir}}" "{{xdg_runtime_dir}}/podman" "{{act_tmp_dir}}"
    @ln -sf "{{project_root}}/scripts/docker-podman-compat.sh" "{{shim_dir}}/docker"
    @if [ ! -S "{{podman_socket_path}}" ]; then \
        rm -f "{{podman_socket_path}}"; \
        : > "{{podman_socket_path}}"; \
    fi

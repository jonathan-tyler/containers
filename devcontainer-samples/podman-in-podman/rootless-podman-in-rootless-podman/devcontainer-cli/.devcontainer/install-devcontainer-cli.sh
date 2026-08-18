#!/usr/bin/env bash
set -euo pipefail

# This sample retains the baseline's temporary unsigned Fedora source. See the
# README before adapting this package transaction for production.
cat > /etc/yum.repos.d/fedora-43-temporary.repo <<'EOF'
[fedora-43-temporary]
name=Fedora 43 temporary Node.js dependency source
baseurl=https://download.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/os/
enabled=1
gpgcheck=0
EOF

dnf -y --no-best --setopt=install_weak_deps=False install nodejs npm
npm install --global '@devcontainers/cli@0.88.0'
npm cache clean --force
[[ "$(devcontainer --version)" == '0.88.0' ]]

rpm -qa --qf '%{NAME}\t%{EVR}\t%{ARCH}\t%{VENDOR}\n' |
  while IFS=$'\t' read -r name evr arch vendor; do
    case "${name}" in
      nodejs*|npm)
        printf '%s\t%s\t%s\t%s\n' "${name}" "${evr}" "${arch}" "${vendor}"
        ;;
    esac
  done >> /usr/local/share/nested-podman/package-provenance.txt
rpm -qa --qf '%{NAME}\t%{EVR}\t%{ARCH}\t%{VENDOR}\n' \
  | sort > /usr/local/share/nested-podman/all-package-provenance.txt
printf '@devcontainers/cli\t%s\n' "$(devcontainer --version)" \
  > /usr/local/share/nested-podman/devcontainer-cli-provenance.txt

rm -f /etc/yum.repos.d/fedora-43-temporary.repo
dnf clean all
rm -rf /var/cache/dnf

if [[ -e /etc/yum.repos.d/fedora-43-temporary.repo ]] ||
   [[ -d /var/cache/dnf &&
      -n "$(find /var/cache/dnf -mindepth 1 -print -quit)" ]]; then
  printf 'Temporary Fedora repository state was not removed.\n' >&2
  exit 1
fi

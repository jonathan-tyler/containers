#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -m)" != x86_64 ]]; then
  printf 'This image is pinned for the verified x86_64 host.\n' >&2
  exit 1
fi

# Hummingbird supplies Podman, its configuration, and the mapping helpers.
# Fedora 43 closes only dependencies absent from the Hummingbird repository.
fedora_gaps=(
  conmon
  crun
  iptables-libs
  libnetfilter_conntrack
  libnfnetlink
  libnftnl
  nftables
  nftables-services
  passt
  yajl
)
for package in "${fedora_gaps[@]}"; do
  if [[ -n "$(dnf repoquery --quiet --qf '%{name}' "${package}")" ]]; then
    printf '%s unexpectedly became available from Hummingbird.\n' "${package}" >&2
    exit 1
  fi
done

# This example matches the tested prototype and therefore disables Fedora RPM
# signature checks. Production users should install and trust the Fedora 43 key,
# set gpgcheck=1, and verify that change before adopting the image.
cat > /etc/yum.repos.d/fedora-43-temporary.repo <<'EOF'
[fedora-43-temporary]
name=Fedora 43 temporary dependency source
baseurl=https://download.fedoraproject.org/pub/fedora/linux/releases/43/Everything/x86_64/os/
enabled=1
gpgcheck=0
EOF

# Pin direct Hummingbird inputs. The solver chooses Hummingbird dependencies
# where available and the confirmed Fedora gaps above for the remaining closure.
dnf -y --no-best --setopt=install_weak_deps=False install \
  podman-5:6.0.2-2.1.hum1 \
  shadow-utils-subid-2:4.19.3-4.hum1

# Preserve package identities in the image so a run can record provenance even
# after the temporary Fedora repository and package-manager metadata are gone.
install -d -m 0755 /usr/local/share/nested-podman
rpm -q --qf '%{NAME}\t%{EVR}\t%{ARCH}\t%{VENDOR}\n' \
  podman containers-common conmon crun shadow-utils shadow-utils-subid \
  > /usr/local/share/nested-podman/package-provenance.txt
rpm -qa --qf '%{NAME}\t%{EVR}\t%{ARCH}\t%{VENDOR}\n' \
  | sort > /usr/local/share/nested-podman/all-package-provenance.txt

rm -f /etc/yum.repos.d/fedora-43-temporary.repo
dnf clean all
rm -rf /var/cache/dnf

if [[ -e /etc/yum.repos.d/fedora-43-temporary.repo ]] ||
   [[ -d /var/cache/dnf &&
      -n "$(find /var/cache/dnf -mindepth 1 -print -quit)" ]]; then
  printf 'Temporary Fedora repository state was not removed.\n' >&2
  exit 1
fi

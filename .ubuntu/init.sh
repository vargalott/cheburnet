#!/bin/bash
set -euxo pipefail
export NEEDRESTART_SUSPEND=1

init_system() {
    timedatectl set-timezone UTC

    # core utils
    apt-get -y update && apt-get -y upgrade
    apt-get -y install bc bmon btop certbot cron curl dnsutils htop iftop jq micro nano net-tools util-linux uuid-runtime vnstat wget

    # docker
    wget -qO- https://get.docker.com | sh
    docker network create --driver bridge --subnet=172.20.0.0/24 --gateway=172.20.0.1 localnet

    # disable unattended upgrades
    cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Unattended-Upgrade "0";
EOF
    systemctl disable --now unattended-upgrades
}

configure_sysctl() {
    wget -qO /etc/sysctl.conf https://raw.githubusercontent.com/vargalott/cheburnet/main/.ubuntu/sysctl.conf

    sysctl --system
}

configure_ssh() {
    local ssh_key="$1"
    [[ -z "$ssh_key" ]] && return

    wget -qO /etc/ssh/sshd_config https://raw.githubusercontent.com/vargalott/cheburnet/main/.ubuntu/sshd_config

    mkdir -p ~/.ssh && chmod 700 ~/.ssh
    touch ~/.ssh/authorized_keys && echo "$ssh_key" > ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys

    rm /etc/update-motd.d/*
    wget -qO /etc/update-motd.d/99-custom https://raw.githubusercontent.com/vargalott/cheburnet/main/.ubuntu/motd.99-custom
    chmod +x /etc/update-motd.d/99-custom

    systemctl daemon-reload && systemctl enable --now ssh.socket
}

configure_dns() {
    wget -qO /etc/systemd/resolved.conf https://raw.githubusercontent.com/vargalott/cheburnet/main/.ubuntu/resolved.conf

    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    systemctl daemon-reload && systemctl enable --now systemd-resolved
}

configure_cron() {
    (crontab -l 2>/dev/null; echo "0 0 * * * /sbin/shutdown -r now") | crontab -
}

configure_ssl() {
    local cert_email="$1"
    local cert_domain="$2"
    [[ -z "$cert_email" || -z "$cert_domain" ]] && return

    certbot certonly --standalone --agree-tos -m "$cert_email" -d "$cert_domain" --non-interactive
}

configure_shell() {
    wget -qO ~/.bashrc https://raw.githubusercontent.com/vargalott/cheburnet/main/.ubuntu/.bashrc
}

# all root
main() {
    local ssh_key="${IU_SSH_KEY:-}"
    local cert_email="${IU_CERT_EMAIL:-}"
    local cert_domain="${IU_CERT_DOMAIN:-}"

    sleep 1 && init_system
    sleep 1 && configure_sysctl
    sleep 1 && configure_ssh "$ssh_key"
    sleep 1 && configure_dns
    sleep 1 && configure_cron
    sleep 1 && configure_ssl "$cert_email" "$cert_domain"
    sleep 1 && configure_shell
}

main "$@"

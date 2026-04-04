#!/bin/bash
set -euo pipefail
export NEEDRESTART_SUSPEND=1

init_system() {
    timedatectl set-timezone UTC

    # core utils
    apt-get -y update && apt-get -y upgrade
    apt-get -y install bc bmon btop certbot cron curl dnsutils htop iftop jq micro nano net-tools util-linux uuid-runtime vnstat wget

    # docker
    curl -fsSL https://get.docker.com | sh
    docker network create --driver bridge --subnet=172.20.0.0/24 --gateway=172.20.0.1 localnet

    # disable unattended upgrades
    cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "0";
APT::Periodic::Unattended-Upgrade "0";
EOF
    systemctl disable --now unattended-upgrades
}

configure_sysctl() {
    cat > /etc/sysctl.conf <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.tcp_syncookies=1
net.ipv4.ip_forward=0

net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
    sysctl --system
}

configure_ssh() {
    local ssh_key="$1"

    if [[ -n "$ssh_key" ]]; then
        cat > /etc/ssh/sshd_config <<'EOF'
ListenAddress 0.0.0.0
Port 8080

Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
KexAlgorithms sntrup761x25519-sha512@openssh.com

PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
KbdInteractiveAuthentication no
UsePAM no

X11Forwarding yes
PrintMotd no

AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        touch ~/.ssh/authorized_keys && echo "$ssh_key" > ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys

        systemctl daemon-reload && systemctl enable --now ssh.socket
    fi
}

configure_dns() {
    cat > /etc/systemd/resolved.conf <<'EOF'
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net
FallbackDNS=1.0.0.1#cloudflare-dns.com 149.112.112.112#dns.quad9.net
Domains=~.
LLMNR=no
MulticastDNS=no
DNSSEC=yes
DNSOverTLS=yes
DNSStubListener=yes
Cache=no-negative
CacheFromLocalhost=no
ReadEtcHosts=yes
ResolveUnicastSingleLabel=no
StaleRetentionSec=0
EOF

    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
    systemctl daemon-reload && systemctl enable --now systemd-resolved
}

configure_cron() {
    (crontab -l 2>/dev/null; echo "0 0 * * * /sbin/shutdown -r now") | crontab -
}

configure_ssl() {
    local cert_email="$1"
    local cert_domain="$2"

    [[ -n "$cert_email" ]] && [[ -n "$cert_domain" ]] && certbot certonly --standalone --agree-tos -m "$cert_email" -d "$cert_domain" --non-interactive
}

configure_shell() {
    cat > ~/.bashrc <<'EOF'
# ~/.bashrc

# 1. Interactive check
[[ -z "$PS1" ]] && return

# 2. History
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=5000
HISTFILESIZE=10000
HISTTIMEFORMAT="%F %T "
shopt -s cmdhist histreedit histverify

# 3. Prompt
shopt -s checkwinsize
[[ -x /usr/bin/lesspipe ]] && eval "$(SHELL=/bin/sh lesspipe)"
if [[ -x /usr/bin/tput ]] && tput setaf 1 >/dev/null 2>&1; then
    base_PS1="\[\033[35m\]\$(/bin/date '+%Y-%m-%d %H:%M:%S') \[\033[1;31m\]\u@\h \[\033[1;34m\]\$(pwd)\[\033[0m\] "
else
    base_PS1="\$(/bin/date '+%Y-%m-%d %H:%M:%S') \u@\h \$(pwd) "
fi
PROMPT_COMMAND='ret=$?; PS1="$base_PS1$( [[ $ret -ne 0 ]] && printf "\001\033[0;31m\002(%d)\001\033[0m\002 " $ret)-> "'

# 4. Colors
if [[ -x /usr/bin/dircolors ]]; then
    eval "$(dircolors -b ~/.dircolors 2>/dev/null || dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# 5. Aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -alF --group-directories-first'
alias ducks='du -hs * | sort -hr'
alias reload='source ~/.bashrc'
alias dcu='docker compose up'
alias dcd='docker compose down'
alias dcr='docker compose restart'
alias dcdu='docker compose down && docker compose up -d'
alias dcl='docker compose logs -f'

# 6. Variables
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LESS='-R'

# 7. Completion
[[ $PS1 && -f /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion

# 8. Extra
shopt -s dotglob globstar
EOF
}

# all root
main() {
    local ssh_key="${IU_SSH_KEY:-}"
    local cert_email="${IU_CERT_EMAIL:-}"
    local cert_domain="${IU_CERT_DOMAIN:-}"

    echo "SSH key: $ssh_key"
    echo "Email for domain certification: $cert_email"
    echo "Certified domain: $cert_domain"

    sleep 1 && init_system
    sleep 1 && configure_sysctl
    sleep 1 && configure_ssh "$ssh_key"
    sleep 1 && configure_dns
    sleep 1 && configure_cron
    sleep 1 && configure_ssl "$cert_email" "$cert_domain"
    sleep 1 && configure_shell
}

main "$@"

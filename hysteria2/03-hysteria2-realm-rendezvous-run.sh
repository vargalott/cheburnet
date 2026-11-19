#!/usr/bin/env bash
set -euo pipefail

# $ git clone https://github.com/HyNetworks/hysteria-realm-server
# $ go build -o hysteria-realm-server
# $ chmod +x ./hysteria-realm-server

BIN="./hysteria-realm-server"
TOKEN="UUID"
LISTEN=":8443"
CERT="fullchain.pem"
KEY="privkey.pem"

PIDFILE="./hysteria-realm-server.pid"
LOGFILE="./hysteria-realm-server.log"

is_running() {
    [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null
}

start() {
    if is_running; then
        echo "already running (pid $(cat "$PIDFILE"))"
        exit 1
    fi

    nohup "$BIN" \
        --token "$TOKEN" \
        --listen "$LISTEN" \
        --cert "$CERT" \
        --key "$KEY" \
        >>"$LOGFILE" 2>&1 &

    echo $! > "$PIDFILE"
    disown
    echo "started, pid $(cat "$PIDFILE"), log: $LOGFILE"
}

stop() {
    if ! is_running; then
        echo "not running"
        rm -f "$PIDFILE"
        exit 1
    fi

    local pid
    pid="$(cat "$PIDFILE")"
    kill "$pid"

    for _ in $(seq 1 20); do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.5
    done

    if kill -0 "$pid" 2>/dev/null; then
        echo "did not exit, sending SIGKILL"
        kill -9 "$pid"
    fi

    rm -f "$PIDFILE"
    echo "stopped"
}

status() {
    if is_running; then
        echo "running (pid $(cat "$PIDFILE"))"
    else
        echo "not running"
    fi
}

case "${1:-}" in
    start)   start ;;
    stop)    stop ;;
    restart) is_running && stop; start ;;
    status)  status ;;
    *)
        echo "usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

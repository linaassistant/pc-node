#!/usr/bin/env bash
# OpenClaw node setup — Zain ke Linux PC ko Huzaifa ke gateway ka node banata hai.
# ONE COMMAND:
#   curl -fsSL https://raw.githubusercontent.com/linaassistant/pc-node/main/setup.sh | sudo bash -s -- --key <TAILSCALE_AUTHKEY>
#
# Kya karta hai: Tailscale install + join, Node.js 20, openclaw CLI, node host service install.
set -euo pipefail

KEY=""; GW="huzaifa-cloud"; PORT=18789; NAME="zain-pc"
while [ $# -gt 0 ]; do
  case "$1" in
    --key) KEY="${2:-}"; shift 2;;
    --gw) GW="${2:-}"; shift 2;;
    --port) PORT="${2:-}"; shift 2;;
    --name) NAME="${2:-}"; shift 2;;
    *) shift;;
  esac
done

say(){ printf "\n\033[92m== %s\033[0m\n" "$1"; }

if [ -z "$KEY" ]; then
  echo "ERROR: Tailscale auth key missing. Use:  --key tskey-auth-XXXX"
  exit 1
fi

say "1/4 Tailscale install + join"
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
tailscale up --authkey "$KEY" --hostname "$NAME" --accept-routes || tailscale up --authkey "$KEY" --accept-routes
tailscale ip -4 || true

say "2/4 Node.js 20"
NEED_NODE=1
if command -v node >/dev/null 2>&1; then
  MAJ=$(node -v | sed 's/^v//' | cut -d. -f1)
  [ "$MAJ" -ge 20 ] 2>/dev/null && NEED_NODE=0
fi
if [ "$NEED_NODE" = "1" ]; then
  export DEBIAN_FRONTEND=noninteractive
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
fi
node -v

say "3/4 openclaw CLI"
npm install -g openclaw
openclaw --version

say "4/4 node host service (gateway: $GW:$PORT)"
openclaw node install --host "$GW" --port "$PORT" --display-name "$NAME" --force || \
  openclaw node run --host "$GW" --port "$PORT" --display-name "$NAME" &
sleep 5
openclaw node status || true

say "DONE — ab Huzaifa pairing approve karega (Telegram par)."

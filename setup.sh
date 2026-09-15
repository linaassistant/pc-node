#!/usr/bin/env bash
# Huzaifa PC-node setup (Kali/Linux) — ONE COMMAND, sab kuch khud karta hai:
#   curl -fsSL https://raw.githubusercontent.com/linaassistant/pc-node/main/setup.sh | sudo bash
#
# Steps: Tailscale install + login (link khud dikhega, click kar dein) -> Node.js 20 ->
#        openclaw CLI -> node host service (gateway: huzaifa-cloud) -> pairing pending.
set -uo pipefail

GW="${GW:-huzaifa-cloud}"
PORT="${PORT:-18789}"
NAME="${NAME:-zain-kali}"

say(){ printf "\n\033[92m== %s\033[0m\n" "$1"; }
warn(){ printf "\033[93m!! %s\033[0m\n" "$1"; }

say "0/5 Basic tools"
export DEBIAN_FRONTEND=noninteractive
command -v curl >/dev/null || (apt-get update -qq && apt-get install -y -qq curl)
apt-get install -y -qq ca-certificates >/dev/null 2>&1 || true

say "1/5 Tailscale"
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
systemctl enable --now tailscaled >/dev/null 2>&1 || true
if ! tailscale status >/dev/null 2>&1; then
  echo "-> Agar link aaye to browser me khol kar authorize kar dein (ek dafa):"
  tailscale up --hostname "$NAME" --accept-routes --timeout 10m || tailscale up --hostname "$NAME" --timeout 10m
fi
tailscale ip -4 2>/dev/null || warn "Tailscale connect nahi hua (login adhoora?)"

say "2/5 Node.js 20"
NEED=1
if command -v node >/dev/null 2>&1; then
  MAJ=$(node -v | sed 's/^v//' | cut -d. -f1); [ "$MAJ" -ge 20 ] 2>/dev/null && NEED=0
fi
if [ "$NEED" = "1" ]; then
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y -qq nodejs
fi
node -v

say "3/5 openclaw CLI"
npm install -g openclaw >/dev/null 2>&1 || npm install -g openclaw
openclaw --version

say "4/5 Node host (gateway $GW:$PORT)"
openclaw node install --host "$GW" --port "$PORT" --display-name "$NAME" --force 2>/dev/null \
  || openclaw node install --host "$GW" --port "$PORT" --display-name "$NAME" \
  || {
    warn "service install fail -> background me chala rahe hain"
    nohup openclaw node run --host "$GW" --port "$PORT" --display-name "$NAME" >/var/log/openclaw-node.log 2>&1 &
    sleep 5
  }

say "5/5 Status"
openclaw node status || true
echo
echo "DONE. Ab Huzaifa pairing approve karega (Telegram)."
echo "Node log: /var/log/openclaw-node.log   |   Config: ~/.openclaw/node.json"

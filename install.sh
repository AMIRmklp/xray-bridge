#!/bin/bash
# ══════════════════════════════════════════════════════════════════
#  XRay Bridge Panel — نصب خودکار روی Ubuntu/Debian
# ══════════════════════════════════════════════════════════════════
set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
info(){ echo -e "${CYAN}[INFO]${NC} $1"; }
ok(){   echo -e "${GREEN}[OK]${NC} $1"; }
warn(){ echo -e "${YELLOW}[WARN]${NC} $1"; }
err(){  echo -e "${RED}[ERR]${NC} $1"; exit 1; }

INSTALL_DIR="/opt/xray-bridge"
SERVICE="xray-bridge"
PANEL_PORT="${PORT:-2054}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║       XRay Bridge Panel Installer    ║"
echo "  ║          نصب‌کننده پنل XRay Bridge   ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"

[[ $EUID -ne 0 ]] && err "با دسترسی root اجرا کنید: sudo bash install.sh"

# ── 1. Node.js ────────────────────────────────────────────────
if ! command -v node &>/dev/null || [[ $(node -v | tr -d 'v' | cut -d. -f1) -lt 18 ]]; then
  info "نصب Node.js 20..."
  apt-get update -qq
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
  apt-get install -y nodejs >/dev/null 2>&1
  ok "Node.js $(node -v) نصب شد"
else
  ok "Node.js $(node -v) موجود است"
fi

# ── 2. XRay Core (اختیاری — اگر نصب نباشد) ──────────────────
if ! command -v xray &>/dev/null && [[ ! -f /usr/local/bin/xray ]]; then
  info "نصب XRay Core..."
  bash -c "$(curl -sL https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install >/dev/null 2>&1 && ok "XRay Core نصب شد" || warn "نصب XRay Core ناموفق — می‌توانید بعداً از داخل پنل نصب کنید"
else
  XVER=$(xray version 2>/dev/null | head -1 || echo "نامشخص")
  ok "XRay موجود: $XVER"
fi

# ── 3. کپی فایل‌ها ───────────────────────────────────────────
info "کپی فایل‌ها به $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR/public" "$INSTALL_DIR/data"
cp "$SCRIPT_DIR/server.js"         "$INSTALL_DIR/server.js"
cp "$SCRIPT_DIR/public/index.html" "$INSTALL_DIR/public/index.html"
chmod 750 "$INSTALL_DIR/server.js"
ok "فایل‌ها کپی شدند"

# ── 4. Systemd service ────────────────────────────────────────
info "ایجاد systemd service..."
cat > /etc/systemd/system/${SERVICE}.service <<EOF
[Unit]
Description=XRay Bridge Panel
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=/usr/bin/node ${INSTALL_DIR}/server.js
Restart=on-failure
RestartSec=5
Environment=PORT=${PANEL_PORT}
StandardOutput=journal
StandardError=journal
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable $SERVICE >/dev/null 2>&1
systemctl restart $SERVICE
sleep 1
systemctl is-active --quiet $SERVICE && ok "سرویس فعال شد" || warn "سرویس شروع نشد — journalctl -u $SERVICE را بررسی کنید"

# ── 5. Firewall ───────────────────────────────────────────────
if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
  ufw allow "$PANEL_PORT/tcp" comment "XRay Bridge Panel" >/dev/null 2>&1
  ufw allow 10808/tcp comment "XRay SOCKS5" >/dev/null 2>&1
  ufw allow 10809/tcp comment "XRay HTTP" >/dev/null 2>&1
  ok "فایروال تنظیم شد"
fi

# ── 6. دستور کوتاه ───────────────────────────────────────────
cat > /usr/local/bin/xb <<'XCMD'
#!/bin/bash
case "$1" in
  start)   systemctl start xray-bridge ;;
  stop)    systemctl stop xray-bridge ;;
  restart) systemctl restart xray-bridge ;;
  status)  systemctl status xray-bridge ;;
  log)     journalctl -u xray-bridge -f ;;
  update)
    cd /opt/xray-bridge
    curl -sL https://raw.githubusercontent.com/AMIRmklp/xray-bridge/main/server.js -o server.js
    systemctl restart xray-bridge
    ;;
  *)  echo "استفاده: xb {start|stop|restart|status|log}" ;;
esac
XCMD
chmod +x /usr/local/bin/xb

# ── نتیجه ────────────────────────────────────────────────────
IP=$(curl -s4 --connect-timeout 3 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}   نصب با موفقیت انجام شد! ✓${NC}"
echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
echo ""
echo -e "  🌐 آدرس پنل:   ${CYAN}http://${IP}:${PANEL_PORT}${NC}"
echo -e "  👤 کاربری:     ${YELLOW}admin${NC}"
echo -e "  🔑 رمز پیش‌فرض: ${YELLOW}admin1234${NC}  ${RED}← حتماً تغییر دهید!${NC}"
echo ""
echo -e "  📡 SOCKS5:     ${CYAN}127.0.0.1:10808${NC}"
echo -e "  📡 HTTP Proxy: ${CYAN}127.0.0.1:10809${NC}"
echo ""
echo -e "  دستورات مفید:"
echo -e "  ${YELLOW}xb start | stop | restart | status | log${NC}"
echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"

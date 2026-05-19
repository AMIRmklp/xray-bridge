# ⛓ XRay Bridge Panel

<div align="center">

![Version](https://img.shields.io/badge/version-2.1.0-blue?style=flat-square)
![Node](https://img.shields.io/badge/node-%3E%3D18-green?style=flat-square&logo=node.js)
![License](https://img.shields.io/badge/license-MIT-orange?style=flat-square)
![XRay](https://img.shields.io/badge/XRay-Core-red?style=flat-square)
![Platform](https://img.shields.io/badge/platform-Ubuntu%20%7C%20Debian-purple?style=flat-square)

**پنل مدیریت تانل XRay برای سرور ایران**

_A self-contained web panel to manage XRay outbound tunnels on Iran servers,_
_bridging traffic through foreign servers without censorship._

</div>

---

## 🏗 معماری / Architecture

```
کاربران (Clients)
      │
      ▼
 ┌─────────────┐
 │  ۳X-UI پنل │  ← سرور ایران (Iran Server)
 │  (Inbound)  │
 └──────┬──────┘
        │ Route via SOCKS5
        ▼
 ┌─────────────────────┐
 │  XRay Bridge Panel  │  ← این پنل (This Panel)
 │  :10808 SOCKS5      │    مدیریت Outbound
 │  :10809 HTTP Proxy  │    Auto delay test & switch
 └──────┬──────────────┘
        │ Tunnel (best config)
        ▼
 ┌─────────────┐
 │ سرور خارج  │  ← Foreign Server
 │ VLESS/VMess │    XRay Outbound
 │ Trojan/SS   │
 └──────┬──────┘
        ▼
    🌐 Internet
```

---

## ✨ قابلیت‌ها / Features

| قابلیت | توضیح |
|--------|-------|
| 🔗 **پارس لینک** | `vless://` `vmess://` `trojan://` `ss://` |
| ⊞ **وارد کردن گروهی** | چند صد لینک را یکجا وارد کنید |
| ⚡ **TCP Delay واقعی** | تست هر N ثانیه (قابل تنظیم) |
| 🔄 **Real Delay** | تست از طریق SOCKS5 پروکسی XRay |
| 🤖 **سوئیچ خودکار** | اتصال به کمترین delay |
| 🌐 **DNS اختصاصی** | هر کانفیگ DNS مستقل دارد |
| 📡 **XHTTP / SplitHTTP** | پشتیبانی کامل (XRay 1.8.24+) |
| ⬇ **نصب XRay** | از داخل پنل با لاگ زنده |
| 💾 **Backup/Restore** | پشتیبان‌گیری JSON |
| 🎨 **صفحه ورود** | رنگ، لوگو، عنوان قابل تنظیم + پیش‌نمایش |
| 🔒 **احراز هویت** | Session-based، تغییر یوزر/پسورد |
| ⬡ **۳X-UI Integration** | اتصال از طریق API |
| 📊 **System Stats** | RAM، CPU، آپتایم، نسخه XRay |
| 📦 **Self-contained** | بدون CDN یا منابع خارجی |

---

## 🚀 نصب سریع / Quick Install

```bash
wget https://github.com/AMIRmklp/xray-bridge/releases/latest/download/xray-bridge.tar.gz
tar -xzf xray-bridge.tar.gz
cd xray-bridge
sudo bash install.sh
```

بعد از نصب:

```
http://YOUR_SERVER_IP:2054
```

| | |
|---|---|
| **یوزر پیش‌فرض** | `admin` |
| **رمز پیش‌فرض** | `admin1234` |

> ⚠️ بعد از اولین ورود، از صفحه **امنیت** رمز را تغییر دهید!

---

## 🔧 نصب دستی / Manual Install

```bash
# Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt install -y nodejs

# XRay Core (یا از داخل پنل نصب کنید)
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# کپی فایل‌ها و اجرا
sudo mkdir -p /opt/xray-bridge/public
sudo cp server.js /opt/xray-bridge/
sudo cp public/index.html /opt/xray-bridge/public/
PORT=2054 node /opt/xray-bridge/server.js
```

اسکریپت `install.sh` به صورت خودکار:
- Node.js نصب می‌کند
- XRay Core نصب می‌کند (در صورت نبود)
- فایل‌ها را به `/opt/xray-bridge` کپی می‌کند
- یک **systemd service** می‌سازد و فعال می‌کند
- فایروال **UFW** را تنظیم می‌کند
- دستور کوتاه **`xb`** را نصب می‌کند

---

## 📡 پروتکل‌های پشتیبانی‌شده

```
vless://UUID@host:443?type=tcp&security=reality&pbk=KEY&sid=ID&sni=google.com&fp=chrome#name
vless://UUID@host:443?type=xhttp&security=tls&mode=auto&path=/&sni=host#name
vmess://BASE64JSON
trojan://PASSWORD@host:443?security=tls&sni=host#name
ss://METHOD:PASSWORD@host:8388#name
```

---

## 🔌 اتصال به ۳X-UI

در پنل ۳X-UI یک **SOCKS5 Outbound** بسازید:

```json
{
  "tag": "xray-bridge",
  "protocol": "socks",
  "settings": {
    "servers": [{ "address": "127.0.0.1", "port": 10808 }]
  }
}
```

سپس در **Routing** قانون اضافه کنید تا ترافیک به این outbound برود.

---

## ⚙️ تنظیمات / Configuration

```json
{
  "socksPort": 10808,
  "httpPort": 10809,
  "autoSwitch": true,
  "autoSwitchInterval": 5,
  "logLevel": "warning",
  "dns1": "1.1.1.1",
  "dns2": "8.8.8.8",
  "localDns": "178.22.122.100",
  "dnsStrategy": "IPIfNonMatch",
  "mux": true,
  "muxConcurrency": 8,
  "routeIranDirect": true,
  "blockAds": false
}
```

متغیر محیطی: `PORT=2054`

---

## 📖 API Reference

همه endpoint ها نیاز به session cookie دارند.

```
POST /login                        احراز هویت
GET  /logout                       خروج

GET    /api/configs                لیست کانفیگ‌ها
POST   /api/configs                افزودن (body: {link} یا manual fields)
POST   /api/configs/bulk           افزودن گروهی (body: {links: "vless://...\n..."})
DELETE /api/configs/:id            حذف
POST   /api/configs/:id/activate   فعال‌سازی
POST   /api/configs/:id/test       تست delay

POST /api/start                    شروع XRay
POST /api/stop                     توقف
POST /api/restart                  ری‌استارت
POST /api/test-all                 تست همه
GET  /api/status                   وضعیت کلی
GET  /api/xray-config              config.json فعلی

GET  /api/settings                 دریافت تنظیمات
POST /api/settings                 ذخیره تنظیمات

POST /api/xray/install             نصب XRay  {version?}
POST /api/xray/uninstall           حذف XRay
GET  /api/xray/install-log         لاگ نصب

POST /api/auth/change-password     {current, newPass}
POST /api/auth/change-username     {username}
POST /api/auth/appearance          {loginTitle, loginLogo, loginBg, loginAccent, panelTitle}
GET  /api/auth/me                  اطلاعات کاربر

POST /api/backup/create            ساخت بکاپ
GET  /api/backup/list              لیست بکاپ‌ها
GET  /api/backup/download/:name    دانلود بکاپ
POST /api/backup/restore           بازیابی {data: base64}

GET    /api/logs?level=all         لاگ‌ها
DELETE /api/logs                   پاک کردن

GET  /api/sysinfo                  اطلاعات سیستم
POST /api/3xui/test                تست اتصال ۳X-UI
```

---

## 🗂 ساختار پروژه

```
xray-bridge/
├── server.js           ← بک‌اند Node.js (zero npm dependencies)
├── public/
│   └── index.html      ← فرانت‌اند کامل (self-contained, no CDN)
├── install.sh          ← اسکریپت نصب خودکار
├── package.json
├── .gitignore
└── README.md
```

پوشه `data/` هنگام اجرا ساخته می‌شود و در `.gitignore` است.

---

## 🔒 توصیه‌های امنیتی

```bash
# محدود کردن دسترسی به پنل فقط از IP خاص
ufw allow from YOUR_IP to any port 2054

# پشت nginx با SSL
server {
    listen 443 ssl;
    server_name panel.yourdomain.com;
    location / { proxy_pass http://127.0.0.1:2054; }
}
```

---

## 📜 License

MIT — آزاد برای استفاده، تغییر و توزیع

---

<div align="center">
Made for Iran 🇮🇷 — ساخته‌شده برای آزادی اینترنت
</div>

#!/bin/bash
# Stadtwache App - Automatisches Installations-Script für Ubuntu/Debian
# Für Root-Server: 212.227.57.238

set -e  # Exit bei Fehlern

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging Funktion
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Root-Berechtigung prüfen
if [[ $EUID -ne 0 ]]; then
   error "Dieses Script muss als root ausgeführt werden!"
fi

log "🚀 Stadtwache App Installation gestartet..."

# 1. System Updates
log "📦 System wird aktualisiert..."
apt update && apt upgrade -y

# 2. Basis-Software installieren
log "🔧 Basis-Software wird installiert..."
apt install -y curl wget git nginx python3 python3-pip python3-venv nodejs npm ufw

# 3. MongoDB Repository und Installation
log "🍃 MongoDB wird installiert..."
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
apt update
apt install -y mongodb-org

# MongoDB starten
systemctl start mongod
systemctl enable mongod

# 4. Arbeitsverzeichnis erstellen
log "📁 Arbeitsverzeichnis wird erstellt..."
mkdir -p /opt/stadtwache
cd /opt/stadtwache

# 5. Code von GitHub klonen (falls Repository verfügbar)
log "📥 Code wird heruntergeladen..."
if git clone https://github.com/hagelbagel03-spec/13.git . 2>/dev/null; then
    log "✅ Code erfolgreich von GitHub geklont"
else:
    warning "⚠️ GitHub Repository nicht verfügbar - Sie müssen den Code manuell kopieren!"
    info "Kopieren Sie Ihre Stadtwache-Dateien nach /opt/stadtwache/"
    read -p "Drücken Sie Enter wenn der Code kopiert wurde..."
fi

# 6. Backend Setup
log "🐍 Backend wird konfiguriert..."
cd /opt/stadtwache/backend

# Python Virtual Environment
python3 -m venv venv
source venv/bin/activate

# Dependencies installieren
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
    log "✅ Backend Dependencies installiert"
else
    error "❌ requirements.txt nicht gefunden!"
fi

# Backend .env erstellen
cat > .env << EOF
MONGO_URL=mongodb://localhost:27017
JWT_SECRET_KEY=$(openssl rand -hex 32)
ENVIRONMENT=production
EOF

log "✅ Backend .env Datei erstellt"

# 7. Frontend Setup
log "⚛️ Frontend wird konfiguriert..."
cd /opt/stadtwache/frontend

# Node.js Dependencies installieren
npm install

# Expo CLI installieren
npm install -g @expo/cli serve

# Frontend .env erstellen
cat > .env << EOF
EXPO_PUBLIC_BACKEND_URL=http://212.227.57.238:8001
EOF

# Production Build erstellen
info "📦 Frontend wird gebaut..."
npx expo export -p web

log "✅ Frontend konfiguriert und gebaut"

# 8. Systemd Services erstellen
log "🔧 Systemd Services werden erstellt..."

# Backend Service
cat > /etc/systemd/system/stadtwache-backend.service << EOF
[Unit]
Description=Stadtwache Backend API
After=network.target mongod.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/stadtwache/backend
Environment=PATH=/opt/stadtwache/backend/venv/bin
ExecStart=/opt/stadtwache/backend/venv/bin/uvicorn server:app --host 0.0.0.0 --port 8001
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Frontend Service
cat > /etc/systemd/system/stadtwache-frontend.service << EOF
[Unit]
Description=Stadtwache Frontend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/stadtwache/frontend
ExecStart=/usr/bin/npx serve dist -l 3000 -s
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

log "✅ Systemd Services erstellt"

# 9. Nginx Konfiguration
log "🌐 Nginx wird konfiguriert..."

cat > /etc/nginx/sites-available/stadtwache << EOF
server {
    listen 80;
    server_name 212.227.57.238;

    # Frontend (Root)
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:8001/api/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # WebSocket Support
    location /socket.io/ {
        proxy_pass http://localhost:8001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Nginx Site aktivieren
ln -sf /etc/nginx/sites-available/stadtwache /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Nginx Konfiguration testen
nginx -t || error "❌ Nginx Konfiguration fehlerhaft!"

log "✅ Nginx konfiguriert"

# 10. Firewall konfigurieren
log "🔥 Firewall wird konfiguriert..."
ufw --force enable
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS
ufw allow 8001/tcp # Backend API (optional)

log "✅ Firewall konfiguriert"

# 11. Services starten
log "🚀 Services werden gestartet..."
systemctl daemon-reload
systemctl enable stadtwache-backend stadtwache-frontend
systemctl start stadtwache-backend
systemctl start stadtwache-frontend
systemctl reload nginx

# Warten bis Services laufen
sleep 5

# 12. Admin-Benutzer erstellen
log "👤 Admin-Benutzer wird erstellt..."

# Admin-Daten abfragen
echo ""
echo -e "${BLUE}=== Admin-Benutzer Konfiguration ===${NC}"
read -p "Admin E-Mail [admin@stadtwache.de]: " ADMIN_EMAIL
ADMIN_EMAIL=${ADMIN_EMAIL:-admin@stadtwache.de}

read -p "Admin Benutzername [Administrator]: " ADMIN_USERNAME
ADMIN_USERNAME=${ADMIN_USERNAME:-Administrator}

read -s -p "Admin Passwort: " ADMIN_PASSWORD
echo ""

read -p "Abteilung [Hauptrevier Schwelm]: " ADMIN_DEPT
ADMIN_DEPT=${ADMIN_DEPT:-"Hauptrevier Schwelm"}

read -p "Dienstnummer [ADMIN001]: " ADMIN_BADGE
ADMIN_BADGE=${ADMIN_BADGE:-ADMIN001}

# Admin-Benutzer erstellen
if curl -s -X POST http://localhost:8001/api/auth/register \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$ADMIN_EMAIL\",
    \"username\": \"$ADMIN_USERNAME\",
    \"password\": \"$ADMIN_PASSWORD\",
    \"role\": \"admin\",
    \"department\": \"$ADMIN_DEPT\",
    \"badge_number\": \"$ADMIN_BADGE\"
  }" > /dev/null; then
    log "✅ Admin-Benutzer erfolgreich erstellt"
else
    warning "⚠️ Admin-Benutzer konnte nicht erstellt werden - Sie können dies später manuell tun"
fi

# 13. Service Status prüfen
log "🔍 Service Status wird geprüft..."

echo ""
echo -e "${BLUE}=== Service Status ===${NC}"

# Backend Status
if systemctl is-active --quiet stadtwache-backend; then
    echo -e "Backend: ${GREEN}✅ Läuft${NC}"
else
    echo -e "Backend: ${RED}❌ Nicht erreichbar${NC}"
fi

# Frontend Status
if systemctl is-active --quiet stadtwache-frontend; then
    echo -e "Frontend: ${GREEN}✅ Läuft${NC}"
else
    echo -e "Frontend: ${RED}❌ Nicht erreichbar${NC}"
fi

# Nginx Status
if systemctl is-active --quiet nginx; then
    echo -e "Nginx: ${GREEN}✅ Läuft${NC}"
else
    echo -e "Nginx: ${RED}❌ Nicht erreichbar${NC}"
fi

# MongoDB Status
if systemctl is-active --quiet mongod; then
    echo -e "MongoDB: ${GREEN}✅ Läuft${NC}"
else
    echo -e "MongoDB: ${RED}❌ Nicht erreichbar${NC}"
fi

# 14. Abschlussmeldung
echo ""
echo -e "${GREEN}🎉 Installation abgeschlossen!${NC}"
echo ""
echo -e "${BLUE}=== Zugriff auf Ihre Stadtwache App ===${NC}"
echo -e "App-URL: ${GREEN}http://212.227.57.238${NC}"
echo -e "Backend-API: ${GREEN}http://212.227.57.238:8001/api/${NC}"
echo -e "Admin-Login: ${GREEN}$ADMIN_EMAIL${NC}"
echo ""
echo -e "${BLUE}=== Nützliche Befehle ===${NC}"
echo "Service Status: systemctl status stadtwache-backend stadtwache-frontend"
echo "Logs anzeigen: journalctl -u stadtwache-backend -f"
echo "Services neustarten: systemctl restart stadtwache-backend stadtwache-frontend"
echo ""
echo -e "${YELLOW}=== Nächste Schritte ===${NC}"
echo "1. Besuchen Sie http://212.227.57.238 in Ihrem Browser"
echo "2. Melden Sie sich mit Ihren Admin-Daten an"
echo "3. Erstellen Sie weitere Benutzer über das Admin-Panel"
echo "4. Optional: SSL-Zertifikat einrichten für HTTPS"
echo ""
log "🚀 Ihre Stadtwache App ist jetzt einsatzbereit!"
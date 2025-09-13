# Stadtwache App - Installation auf Root-Server (212.227.57.238)

## 🚀 Schritt-für-Schritt Installation

### 1. Server-Vorbereitung

```bash
# Auf Ihrem Root-Server (212.227.57.238) anmelden
ssh root@212.227.57.238

# System aktualisieren
apt update && apt upgrade -y

# Erforderliche Software installieren
apt install -y curl wget git nginx python3 python3-pip python3-venv nodejs npm
```

### 2. MongoDB installieren

```bash
# MongoDB Repository hinzufügen
curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list

# MongoDB installieren
apt update
apt install -y mongodb-org

# MongoDB starten und aktivieren
systemctl start mongod
systemctl enable mongod
systemctl status mongod
```

### 3. Stadtwache-App Code herunterladen

```bash
# Arbeitsverzeichnis erstellen
mkdir -p /opt/stadtwache
cd /opt/stadtwache

# Code von GitHub klonen (Ihr Repository)
git clone https://github.com/hagelbagel03-spec/13.git .

# Oder Code direkt kopieren (falls Sie Änderungen haben)
# Kopieren Sie die aktuellen Dateien von Ihrer Entwicklungsumgebung
```

### 4. Backend installieren und konfigurieren

```bash
# Zum Backend-Verzeichnis wechseln
cd /opt/stadtwache/backend

# Python Virtual Environment erstellen
python3 -m venv venv
source venv/bin/activate

# Dependencies installieren
pip install -r requirements.txt

# .env Datei erstellen
cat > .env << EOF
MONGO_URL=mongodb://localhost:27017
JWT_SECRET_KEY=ihr-geheimer-jwt-schluessel-hier
ENVIRONMENT=production
EOF

# Backend testen
python -m uvicorn server:app --host 0.0.0.0 --port 8001
# (Mit Ctrl+C stoppen nach Test)
```

### 5. Frontend installieren und konfigurieren

```bash
# Zum Frontend-Verzeichnis wechseln
cd /opt/stadtwache/frontend

# Node.js Dependencies installieren
npm install

# Expo CLI global installieren
npm install -g @expo/cli

# .env Datei für Production erstellen
cat > .env << EOF
EXPO_PUBLIC_BACKEND_URL=http://212.227.57.238:8001
EOF

# Build für Production erstellen
npx expo export -p web
```

### 6. Systemd Services erstellen

#### Backend Service:
```bash
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
```

#### Frontend Service:
```bash
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
```

### 7. Nginx Reverse Proxy konfigurieren

```bash
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

    # WebSocket Support für Real-time Features
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
ln -s /etc/nginx/sites-available/stadtwache /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Nginx konfiguration testen
nginx -t

# Nginx neu laden
systemctl reload nginx
```

### 8. Services starten

```bash
# Services aktivieren und starten
systemctl daemon-reload
systemctl enable stadtwache-backend
systemctl enable stadtwache-frontend
systemctl start stadtwache-backend
systemctl start stadtwache-frontend

# Status prüfen
systemctl status stadtwache-backend
systemctl status stadtwache-frontend
systemctl status nginx
systemctl status mongod
```

### 9. Firewall konfigurieren

```bash
# UFW Firewall aktivieren (falls noch nicht aktiv)
ufw enable

# Ports öffnen
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS (für später)
ufw allow 22/tcp    # SSH
ufw allow 8001/tcp  # Backend API (optional, für direkten Zugriff)

# Status prüfen
ufw status
```

### 10. SSL/HTTPS einrichten (Empfohlen)

```bash
# Certbot installieren
apt install -y certbot python3-certbot-nginx

# SSL Zertifikat beantragen (Domain erforderlich)
# certbot --nginx -d ihr-domain.de

# Oder selbstsigniertes Zertifikat für IP-Adresse
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/stadtwache.key \
    -out /etc/ssl/certs/stadtwache.crt \
    -subj "/C=DE/ST=NRW/L=Schwelm/O=Stadtwache/CN=212.227.57.238"
```

### 11. Admin-Benutzer erstellen

```bash
# Backend API nutzen um ersten Admin zu erstellen
curl -X POST http://212.227.57.238:8001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@stadtwache.de",
    "username": "Administrator",
    "password": "IhrSicheresPasswort123!",
    "role": "admin",
    "department": "Hauptrevier Schwelm",
    "badge_number": "ADMIN001"
  }'
```

### 12. Monitoring und Logs

```bash
# Service Logs anzeigen
journalctl -u stadtwache-backend -f
journalctl -u stadtwache-frontend -f
journalctl -u nginx -f

# MongoDB Logs
journalctl -u mongod -f

# Service Status prüfen
systemctl status stadtwache-backend stadtwache-frontend nginx mongod
```

## 🎯 Zugriff auf die App

Nach erfolgreicher Installation:

- **App-URL:** http://212.227.57.238
- **Backend-API:** http://212.227.57.238:8001/api/
- **Admin-Login:** admin@stadtwache.de / IhrSicheresPasswort123!

## 🔧 Wartung und Updates

### Code Updates:
```bash
cd /opt/stadtwache
git pull origin main

# Backend neustarten
systemctl restart stadtwache-backend

# Frontend neu builden und neustarten
cd frontend
npx expo export -p web
systemctl restart stadtwache-frontend
```

### Backup erstellen:
```bash
# MongoDB Backup
mongodump --out /backup/stadtwache-$(date +%Y%m%d)

# Code Backup
tar -czf /backup/stadtwache-code-$(date +%Y%m%d).tar.gz /opt/stadtwache
```

## 🚨 Troubleshooting

### Service läuft nicht:
```bash
systemctl status stadtwache-backend
journalctl -u stadtwache-backend -n 50
```

### Verbindungsprobleme:
```bash
# Ports prüfen
netstat -tlnp | grep -E ':(80|8001|3000|27017)'

# Firewall prüfen
ufw status numbered
```

### MongoDB Probleme:
```bash
systemctl status mongod
mongo --eval "db.adminCommand('listCollections')"
```

## ✅ Erfolgreich installiert!

Ihre Stadtwache-App läuft jetzt auf http://212.227.57.238 und ist bereit für den Produktionseinsatz!
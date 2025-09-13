# Stadtwache App - Server Deployment Konfiguration

## Server Details
- **IP-Adresse (IPv4):** 212.227.57.238  
- **IP-Adresse (IPv6):** 2a02:2479:39:4500::1
- **Backend Port:** 8001
- **Frontend Port:** 3000

## Aktuelle Konfiguration

### Frontend (.env)
```
EXPO_PUBLIC_BACKEND_URL=http://212.227.57.238:8001
```

### Backend (server.py)
```python
# CORS bereits konfiguriert für alle Origins
app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Server läuft auf:
uvicorn server:app --host 0.0.0.0 --port 8001
```

## Für Deployment auf Ihren Root-Server (212.227.57.238):

### 1. Backend starten
```bash
cd /pfad/zu/backend
pip install -r requirements.txt
uvicorn server:app --host 0.0.0.0 --port 8001
```

### 2. MongoDB
```bash
# MongoDB sollte laufen auf:
mongodb://localhost:27017
```

### 3. Firewall/Ports öffnen
```bash
# Port 8001 für Backend API
sudo ufw allow 8001

# Port 3000 für Frontend (optional, wenn auch Frontend auf Server)
sudo ufw allow 3000
```

### 4. Nginx Reverse Proxy (empfohlen)
```nginx
server {
    listen 80;
    server_name 212.227.57.238;
    
    location /api/ {
        proxy_pass http://localhost:8001/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location / {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## App-Verhalten
- ✅ App verbindet sich automatisch mit 212.227.57.238:8001
- ✅ Keine manuelle Konfiguration durch Benutzer erforderlich
- ✅ Login-Screen zeigt Server-IP an
- ✅ Alle API-Calls gehen an Ihren Root-Server

## Demo-Benutzer
- **Email:** demo@stadtwache.de
- **Passwort:** demo123
- **Rolle:** Administrator

## Nächste Schritte
1. Code auf Ihren Server (212.227.57.238) kopieren
2. Dependencies installieren
3. MongoDB starten
4. Backend starten
5. App ist bereit für Benutzer!
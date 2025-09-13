# Stadtwache App - Windows Server Installation

## 🖥️ Installation auf Windows Server (212.227.57.238)

### Schritt 1: Erforderliche Software herunterladen

**Laden Sie folgende Programme herunter:**

1. **Python 3.11+**: https://www.python.org/downloads/windows/
   - Wählen Sie "Windows installer (64-bit)"
   - ✅ **WICHTIG**: Bei Installation "Add Python to PATH" anhaken!

2. **Node.js 18+ LTS**: https://nodejs.org/
   - Wählen Sie "Windows Installer (.msi)" 64-bit

3. **MongoDB Community Server**: https://www.mongodb.com/try/download/community
   - Wählen Sie "Windows x64"
   - Format: "msi"

4. **Git für Windows**: https://git-scm.com/download/win
   - Standard-Installation

5. **Visual Studio Code** (optional): https://code.visualstudio.com/

### Schritt 2: Software installieren

#### Python installieren:
```
1. Python-Installer als Administrator ausführen
2. ✅ "Add Python to PATH" aktivieren
3. "Install Now" klicken
4. Installation abwarten
```

#### Node.js installieren:
```
1. Node.js-Installer als Administrator ausführen
2. Standard-Installation durchführen
3. Neustart des Servers empfohlen
```

#### MongoDB installieren:
```
1. MongoDB-Installer als Administrator ausführen
2. "Complete" Installation wählen
3. ✅ "Install MongoDB as a Service" aktivieren
4. ✅ "Run service as Network Service user" wählen
5. Installation abschließen
```

#### Git installieren:
```
1. Git-Installer ausführen
2. Standard-Einstellungen übernehmen
3. Installation abschließen
```

### Schritt 3: Installation prüfen

**PowerShell als Administrator öffnen und prüfen:**

```powershell
# Python prüfen
python --version

# Node.js prüfen
node --version
npm --version

# Git prüfen
git --version

# MongoDB Service prüfen
Get-Service -Name MongoDB
```

### Schritt 4: Stadtwache Code herunterladen

```powershell
# Arbeitsverzeichnis erstellen
New-Item -ItemType Directory -Path "C:\Stadtwache" -Force
Set-Location "C:\Stadtwache"

# Code von GitHub klonen
git clone https://github.com/hagelbagel03-spec/13.git .

# Oder manuell herunterladen:
# https://github.com/hagelbagel03-spec/13/archive/refs/heads/main.zip
# Entpacken nach C:\Stadtwache\
```

### Schritt 5: Backend konfigurieren

```powershell
# Zum Backend-Verzeichnis wechseln
Set-Location "C:\Stadtwache\backend"

# Python Virtual Environment erstellen
python -m venv venv

# Virtual Environment aktivieren
.\venv\Scripts\Activate.ps1

# Dependencies installieren
pip install -r requirements.txt
```

**Backend .env Datei erstellen:**
```powershell
# .env Datei erstellen
@"
MONGO_URL=mongodb://localhost:27017
JWT_SECRET_KEY=IhrSicheresJWTSecretHier123!@#
ENVIRONMENT=production
"@ | Out-File -FilePath ".env" -Encoding UTF8
```

### Schritt 6: Frontend konfigurieren

```powershell
# Zum Frontend-Verzeichnis wechseln
Set-Location "C:\Stadtwache\frontend"

# Dependencies installieren
npm install

# Expo CLI global installieren
npm install -g @expo/cli serve

# Frontend .env Datei erstellen
@"
EXPO_PUBLIC_BACKEND_URL=http://212.227.57.238:8001
"@ | Out-File -FilePath ".env" -Encoding UTF8

# Production Build erstellen
npx expo export -p web
```

### Schritt 7: Windows Services erstellen

#### Backend Service erstellen:

**Datei: `C:\Stadtwache\backend\start-backend.bat`**
```batch
@echo off
cd /d "C:\Stadtwache\backend"
call venv\Scripts\activate.bat
python -m uvicorn server:app --host 0.0.0.0 --port 8001
```

**PowerShell als Administrator:**
```powershell
# NSSM (Non-Sucking Service Manager) herunterladen
# Von: https://nssm.cc/download
# Entpacken nach C:\Tools\nssm\

# Backend Service erstellen
C:\Tools\nssm\win64\nssm.exe install StadtwacheBackend "C:\Stadtwache\backend\start-backend.bat"
C:\Tools\nssm\win64\nssm.exe set StadtwacheBackend AppDirectory "C:\Stadtwache\backend"
C:\Tools\nssm\win64\nssm.exe set StadtwacheBackend DisplayName "Stadtwache Backend API"
C:\Tools\nssm\win64\nssm.exe set StadtwacheBackend Description "Stadtwache Backend API Service"

# Service starten
Start-Service StadtwacheBackend
```

#### Frontend Service erstellen:

**Datei: `C:\Stadtwache\frontend\start-frontend.bat`**
```batch
@echo off
cd /d "C:\Stadtwache\frontend"
npx serve dist -l 3000 -s
```

**PowerShell als Administrator:**
```powershell
# Frontend Service erstellen
C:\Tools\nssm\win64\nssm.exe install StadtwacheFrontend "C:\Stadtwache\frontend\start-frontend.bat"
C:\Tools\nssm\win64\nssm.exe set StadtwacheFrontend AppDirectory "C:\Stadtwache\frontend"
C:\Tools\nssm\win64\nssm.exe set StadtwacheFrontend DisplayName "Stadtwache Frontend"
C:\Tools\nssm\win64\nssm.exe set StadtwacheFrontend Description "Stadtwache Frontend Web Service"

# Service starten
Start-Service StadtwacheFrontend
```

### Schritt 8: IIS Reverse Proxy (Empfohlen)

#### IIS installieren:
```powershell
# IIS Features aktivieren
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole, IIS-WebServer, IIS-CommonHttpFeatures, IIS-HttpErrors, IIS-HttpLogging, IIS-HttpRedirect, IIS-ApplicationDevelopment, IIS-NetFxExtensibility45, IIS-HealthAndDiagnostics, IIS-HttpCompressionStatic, IIS-Security, IIS-RequestFiltering, IIS-StaticContent, IIS-DefaultDocument, IIS-DirectoryBrowsing, IIS-ASPNET45
```

#### ARR (Application Request Routing) installieren:
1. **URL Rewrite Module**: https://www.iis.net/downloads/microsoft/url-rewrite
2. **Application Request Routing**: https://www.iis.net/downloads/microsoft/application-request-routing

#### IIS Konfiguration:

**web.config in C:\inetpub\wwwroot\ erstellen:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <rewrite>
            <rules>
                <!-- Backend API Proxy -->
                <rule name="Backend API" stopProcessing="true">
                    <match url="^api/(.*)" />
                    <action type="Rewrite" url="http://localhost:8001/api/{R:1}" />
                </rule>
                
                <!-- Frontend Proxy -->
                <rule name="Frontend" stopProcessing="true">
                    <match url="^(.*)$" />
                    <action type="Rewrite" url="http://localhost:3000/{R:1}" />
                </rule>
            </rules>
        </rewrite>
    </system.webServer>
</configuration>
```

### Schritt 9: Windows Firewall konfigurieren

```powershell
# Firewall-Regeln hinzufügen
New-NetFirewallRule -DisplayName "Stadtwache HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow
New-NetFirewallRule -DisplayName "Stadtwache HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow
New-NetFirewallRule -DisplayName "Stadtwache Backend" -Direction Inbound -Protocol TCP -LocalPort 8001 -Action Allow
New-NetFirewallRule -DisplayName "Stadtwache Frontend" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow
```

### Schritt 10: Admin-Benutzer erstellen

```powershell
# Backend API testen
Invoke-RestMethod -Uri "http://localhost:8001/api/" -Method GET

# Admin-Benutzer erstellen
$adminData = @{
    email = "admin@stadtwache.de"
    username = "Administrator"
    password = "IhrSicheresPasswort123!"
    role = "admin"
    department = "Hauptrevier Schwelm"
    badge_number = "ADMIN001"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8001/api/auth/register" -Method POST -Body $adminData -ContentType "application/json"
```

### Schritt 11: Services prüfen

```powershell
# Service Status prüfen
Get-Service -Name MongoDB, StadtwacheBackend, StadtwacheFrontend

# Services neustarten
Restart-Service StadtwacheBackend, StadtwacheFrontend
```

## 🎯 Alternative: Docker Installation (Einfacher)

**Falls Sie Docker Desktop installieren möchten:**

### Docker Desktop installieren:
1. **Docker Desktop für Windows**: https://www.docker.com/products/docker-desktop/
2. Installation als Administrator durchführen
3. WSL 2 aktivieren (wird automatisch angeboten)

### Mit Docker starten:
```powershell
# Zum Projekt-Verzeichnis
Set-Location "C:\Stadtwache"

# Docker Compose Datei erstellen
@"
version: '3.8'
services:
  mongodb:
    image: mongo:7
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db

  backend:
    build: ./backend
    ports:
      - "8001:8001"
    depends_on:
      - mongodb
    environment:
      - MONGO_URL=mongodb://mongodb:27017
      - JWT_SECRET_KEY=IhrSicheresJWTSecretHier123!

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    depends_on:
      - backend

volumes:
  mongodb_data:
"@ | Out-File -FilePath "docker-compose.yml" -Encoding UTF8

# Services starten
docker-compose up -d
```

## 🚀 Nach der Installation

**Ihre Stadtwache App ist erreichbar unter:**
- **App-URL**: http://212.227.57.238
- **Backend-API**: http://212.227.57.238:8001/api/
- **Admin-Login**: admin@stadtwache.de / IhrSicheresPasswort123!

## 🔧 Wartung

### Services verwalten:
```powershell
# Status prüfen
Get-Service StadtwacheBackend, StadtwacheFrontend

# Neustarten
Restart-Service StadtwacheBackend, StadtwacheFrontend

# Stoppen
Stop-Service StadtwacheBackend, StadtwacheFrontend

# Starten
Start-Service StadtwacheBackend, StadtwacheFrontend
```

### Logs anzeigen:
```powershell
# Windows Event Log
Get-EventLog -LogName Application -Source StadtwacheBackend -Newest 50
```

### Updates durchführen:
```powershell
# Code aktualisieren
Set-Location "C:\Stadtwache"
git pull origin main

# Services neustarten
Restart-Service StadtwacheBackend, StadtwacheFrontend
```

## 🆘 Hilfe bei Problemen

### Häufige Probleme:

1. **Services starten nicht:**
   - PowerShell als Administrator öffnen
   - `Get-Service` verwenden um Status zu prüfen
   - Pfade in den .bat Dateien überprüfen

2. **Port bereits belegt:**
   ```powershell
   netstat -an | findstr :8001
   netstat -an | findstr :3000
   ```

3. **MongoDB verbindet nicht:**
   ```powershell
   Get-Service MongoDB
   # Falls nicht läuft: Start-Service MongoDB
   ```

4. **Python/Node nicht gefunden:**
   - PATH-Variable prüfen
   - Neustart des Servers
   - Neuinstallation mit "Add to PATH"

**Ihre Stadtwache App läuft jetzt auf Windows Server! 🎉**
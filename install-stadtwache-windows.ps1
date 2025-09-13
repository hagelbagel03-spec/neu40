# Stadtwache App - Windows Installation Script
# Für Windows Server 2019/2022 oder Windows 10/11

param(
    [string]$InstallPath = "C:\Stadtwache",
    [string]$ServerIP = "212.227.57.238"
)

# Administrator-Berechtigung prüfen
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "❌ Dieses Script muss als Administrator ausgeführt werden!" -ForegroundColor Red
    Read-Host "Drücken Sie Enter zum Beenden"
    exit 1
}

Write-Host "🚀 Stadtwache App Windows Installation gestartet..." -ForegroundColor Green
Write-Host "📍 Server IP: $ServerIP" -ForegroundColor Blue
Write-Host "📁 Installations-Pfad: $InstallPath" -ForegroundColor Blue

# Chocolatey installieren (Package Manager für Windows)
Write-Host "📦 Chocolatey Package Manager wird installiert..." -ForegroundColor Yellow
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
try {
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "✅ Chocolatey erfolgreich installiert" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Chocolatey Installation fehlgeschlagen - manuelle Installation erforderlich" -ForegroundColor Yellow
}

# Erforderliche Software installieren
Write-Host "🔧 Erforderliche Software wird installiert..." -ForegroundColor Yellow

# Python installieren
if (!(Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Host "🐍 Python wird installiert..." -ForegroundColor Blue
    choco install python -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "✅ Python installiert" -ForegroundColor Green
} else {
    Write-Host "✅ Python bereits installiert" -ForegroundColor Green
}

# Node.js installieren
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "🟢 Node.js wird installiert..." -ForegroundColor Blue
    choco install nodejs -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "✅ Node.js installiert" -ForegroundColor Green
} else {
    Write-Host "✅ Node.js bereits installiert" -ForegroundColor Green
}

# Git installieren
if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "📡 Git wird installiert..." -ForegroundColor Blue
    choco install git -y
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "✅ Git installiert" -ForegroundColor Green
} else {
    Write-Host "✅ Git bereits installiert" -ForegroundColor Green
}

# MongoDB installieren
$mongoService = Get-Service -Name MongoDB -ErrorAction SilentlyContinue
if (!$mongoService) {
    Write-Host "🍃 MongoDB wird installiert..." -ForegroundColor Blue
    choco install mongodb -y
    Write-Host "✅ MongoDB installiert" -ForegroundColor Green
} else {
    Write-Host "✅ MongoDB bereits installiert" -ForegroundColor Green
}

# NSSM installieren (für Windows Services)
if (!(Test-Path "C:\Tools\nssm\win64\nssm.exe")) {
    Write-Host "🔧 NSSM wird installiert..." -ForegroundColor Blue
    choco install nssm -y
    Write-Host "✅ NSSM installiert" -ForegroundColor Green
} else {
    Write-Host "✅ NSSM bereits installiert" -ForegroundColor Green
}

# Arbeitsverzeichnis erstellen
Write-Host "📁 Arbeitsverzeichnis wird erstellt..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
Set-Location $InstallPath

# Code von GitHub herunterladen
Write-Host "📥 Stadtwache Code wird heruntergeladen..." -ForegroundColor Yellow
try {
    if (Test-Path ".git") {
        git pull origin main
        Write-Host "✅ Code aktualisiert" -ForegroundColor Green
    } else {
        git clone https://github.com/hagelbagel03-spec/13.git .
        Write-Host "✅ Code heruntergeladen" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Git Clone fehlgeschlagen. Code manuell herunterladen:" -ForegroundColor Yellow
    Write-Host "   https://github.com/hagelbagel03-spec/13/archive/refs/heads/main.zip" -ForegroundColor Cyan
    Read-Host "Code manuell entpacken und Enter drücken"
}

# Backend konfigurieren
Write-Host "🐍 Backend wird konfiguriert..." -ForegroundColor Yellow
Set-Location "$InstallPath\backend"

# Python Virtual Environment
if (!(Test-Path "venv")) {
    python -m venv venv
    Write-Host "✅ Virtual Environment erstellt" -ForegroundColor Green
}

# Virtual Environment aktivieren und Dependencies installieren
& ".\venv\Scripts\Activate.ps1"
pip install -r requirements.txt
Write-Host "✅ Backend Dependencies installiert" -ForegroundColor Green

# Backend .env Datei erstellen
$backendEnv = @"
MONGO_URL=mongodb://localhost:27017
JWT_SECRET_KEY=$((New-Guid).Guid.Replace('-',''))
ENVIRONMENT=production
"@
$backendEnv | Out-File -FilePath ".env" -Encoding UTF8
Write-Host "✅ Backend .env erstellt" -ForegroundColor Green

# Backend Start-Script erstellen
$backendBat = @"
@echo off
cd /d "$InstallPath\backend"
call venv\Scripts\activate.bat
python -m uvicorn server:app --host 0.0.0.0 --port 8001
"@
$backendBat | Out-File -FilePath "start-backend.bat" -Encoding ASCII
Write-Host "✅ Backend Start-Script erstellt" -ForegroundColor Green

# Frontend konfigurieren
Write-Host "⚛️ Frontend wird konfiguriert..." -ForegroundColor Yellow
Set-Location "$InstallPath\frontend"

# Dependencies installieren
npm install
npm install -g @expo/cli serve
Write-Host "✅ Frontend Dependencies installiert" -ForegroundColor Green

# Frontend .env erstellen
$frontendEnv = @"
EXPO_PUBLIC_BACKEND_URL=http://$ServerIP`:8001
"@
$frontendEnv | Out-File -FilePath ".env" -Encoding UTF8
Write-Host "✅ Frontend .env erstellt" -ForegroundColor Green

# Frontend builden
Write-Host "📦 Frontend wird gebaut..." -ForegroundColor Blue
npx expo export -p web
Write-Host "✅ Frontend gebaut" -ForegroundColor Green

# Frontend Start-Script erstellen
$frontendBat = @"
@echo off
cd /d "$InstallPath\frontend"
npx serve dist -l 3000 -s
"@
$frontendBat | Out-File -FilePath "start-frontend.bat" -Encoding ASCII
Write-Host "✅ Frontend Start-Script erstellt" -ForegroundColor Green

# Windows Services erstellen
Write-Host "🔧 Windows Services werden erstellt..." -ForegroundColor Yellow

# MongoDB Service starten
Start-Service MongoDB -ErrorAction SilentlyContinue
Set-Service MongoDB -StartupType Automatic

# Backend Service
$backendServiceExists = Get-Service -Name StadtwacheBackend -ErrorAction SilentlyContinue
if (!$backendServiceExists) {
    & "C:\ProgramData\chocolatey\lib\NSSM\tools\nssm.exe" install StadtwacheBackend "$InstallPath\backend\start-backend.bat"
    & "C:\ProgramData\chocolatey\lib\NSSM\tools\nssm.exe" set StadtwacheBackend AppDirectory "$InstallPath\backend"
    & "C:\ProgramData\chocolatey\lib\NSSM\tools\nssm.exe" set StadtwacheBackend DisplayName "Stadtwache Backend API"
    & "C:\ProgramData\chocolatey\lib\NSSM\tools\nssm.exe" set StadtwacheBackend Description "Stadtwache Backend API Service"
    Write-Host "✅ Backend Service erstellt" -ForegroundColor Green
}

# Frontend Service
$frontendServiceExists = Get-Service -Name StadtwacheFrontend -ErrorAction SilentlyContinue
if (!$frontendServiceExists) {
    & "C:\ProgramData\chocolatey\lib\NSSM\tools\nssm.exe" install StadtwacheFrontend "$InstallPath\frontend\start-frontend.bat"
    & "C:\ProgramData\chocolatey\lib\NSSM\tools\nssm.exe" set StadtwacheFrontend AppDirectory "$InstallPath\frontend"
    & "C:\ProgramData\chocolatey\lib\NSSM\tools\nssm.exe" set StadtwacheFrontend DisplayName "Stadtwache Frontend"
    & "C:\ProgramData\chocolatey\lib\NSSM\tools\nssm.exe" set StadtwacheFrontend Description "Stadtwache Frontend Service"
    Write-Host "✅ Frontend Service erstellt" -ForegroundColor Green
}

# Services starten
Write-Host "🚀 Services werden gestartet..." -ForegroundColor Yellow
Start-Service StadtwacheBackend
Start-Service StadtwacheFrontend
Write-Host "✅ Services gestartet" -ForegroundColor Green

# Firewall konfigurieren
Write-Host "🔥 Windows Firewall wird konfiguriert..." -ForegroundColor Yellow
New-NetFirewallRule -DisplayName "Stadtwache HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Stadtwache HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Stadtwache Backend" -Direction Inbound -Protocol TCP -LocalPort 8001 -Action Allow -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "Stadtwache Frontend" -Direction Inbound -Protocol TCP -LocalPort 3000 -Action Allow -ErrorAction SilentlyContinue
Write-Host "✅ Firewall konfiguriert" -ForegroundColor Green

# Warten bis Services laufen
Write-Host "⏳ Warte bis Services laufen..." -ForegroundColor Blue
Start-Sleep -Seconds 10

# Backend testen
Write-Host "🧪 Backend wird getestet..." -ForegroundColor Blue
try {
    $testResponse = Invoke-RestMethod -Uri "http://localhost:8001/api/" -Method GET -TimeoutSec 10
    if ($testResponse.message -eq "Stadtwache API") {
        Write-Host "✅ Backend läuft korrekt" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ Backend möglicherweise noch nicht bereit" -ForegroundColor Yellow
}

# Admin-Benutzer erstellen
Write-Host "👤 Admin-Benutzer wird erstellt..." -ForegroundColor Yellow

# Admin-Daten abfragen
Write-Host ""
Write-Host "=== Admin-Benutzer Konfiguration ===" -ForegroundColor Cyan
$adminEmail = Read-Host "Admin E-Mail [admin@stadtwache.de]"
if (!$adminEmail) { $adminEmail = "admin@stadtwache.de" }

$adminUsername = Read-Host "Admin Benutzername [Administrator]"
if (!$adminUsername) { $adminUsername = "Administrator" }

$adminPassword = Read-Host "Admin Passwort" -AsSecureString
$adminPasswordText = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword))

$adminDept = Read-Host "Abteilung [Hauptrevier Schwelm]"
if (!$adminDept) { $adminDept = "Hauptrevier Schwelm" }

$adminBadge = Read-Host "Dienstnummer [ADMIN001]"
if (!$adminBadge) { $adminBadge = "ADMIN001" }

# Admin-Benutzer erstellen
$adminData = @{
    email = $adminEmail
    username = $adminUsername
    password = $adminPasswordText
    role = "admin"
    department = $adminDept
    badge_number = $adminBadge
} | ConvertTo-Json

try {
    Start-Sleep -Seconds 5  # Zusätzliche Zeit für Backend-Start
    $createResponse = Invoke-RestMethod -Uri "http://localhost:8001/api/auth/register" -Method POST -Body $adminData -ContentType "application/json"
    Write-Host "✅ Admin-Benutzer erfolgreich erstellt" -ForegroundColor Green
} catch {
    Write-Host "⚠️ Admin-Benutzer konnte nicht erstellt werden - Dies können Sie später manuell tun" -ForegroundColor Yellow
}

# Service Status prüfen
Write-Host ""
Write-Host "=== Service Status ===" -ForegroundColor Cyan

$services = @("MongoDB", "StadtwacheBackend", "StadtwacheFrontend")
foreach ($service in $services) {
    $serviceStatus = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($serviceStatus -and $serviceStatus.Status -eq "Running") {
        Write-Host "$service`: ✅ Läuft" -ForegroundColor Green
    } else {
        Write-Host "$service`: ❌ Nicht erreichbar" -ForegroundColor Red
    }
}

# Abschlussmeldung
Write-Host ""
Write-Host "🎉 Installation abgeschlossen!" -BackgroundColor Green -ForegroundColor Black
Write-Host ""
Write-Host "=== Zugriff auf Ihre Stadtwache App ===" -ForegroundColor Cyan
Write-Host "App-URL: http://$ServerIP" -ForegroundColor Green
Write-Host "Backend-API: http://$ServerIP`:8001/api/" -ForegroundColor Green
Write-Host "Admin-Login: $adminEmail" -ForegroundColor Green
Write-Host ""
Write-Host "=== Nützliche Befehle ===" -ForegroundColor Cyan
Write-Host "Service Status: Get-Service StadtwacheBackend, StadtwacheFrontend" -ForegroundColor White
Write-Host "Services neustarten: Restart-Service StadtwacheBackend, StadtwacheFrontend" -ForegroundColor White
Write-Host "Services stoppen: Stop-Service StadtwacheBackend, StadtwacheFrontend" -ForegroundColor White
Write-Host ""
Write-Host "=== Nächste Schritte ===" -ForegroundColor Yellow
Write-Host "1. Besuchen Sie http://$ServerIP in Ihrem Browser" -ForegroundColor White
Write-Host "2. Melden Sie sich mit Ihren Admin-Daten an" -ForegroundColor White
Write-Host "3. Erstellen Sie weitere Benutzer über das Admin-Panel" -ForegroundColor White
Write-Host "4. Optional: IIS Reverse Proxy einrichten (siehe Anleitung)" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Ihre Stadtwache App ist jetzt einsatzbereit!" -ForegroundColor Green

Read-Host "Drücken Sie Enter zum Beenden"
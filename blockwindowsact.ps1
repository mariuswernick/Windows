# Microsoft Endpunkte Firewall Block Script (PowerShell)
# Als Administrator ausführen!

# Überprüfe Administrator-Rechte
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "FEHLER: Dieses Script muss als Administrator ausgeführt werden!" -ForegroundColor Red
    Write-Host "PowerShell als Administrator starten und Script erneut ausführen." -ForegroundColor Yellow
    Read-Host "Drücke Enter zum Beenden"
    exit 1
}

Write-Host "Blockiere Microsoft Endpunkte in der Windows Firewall..." -ForegroundColor Green

# Domain-Liste
$domains = @(
    "go.microsoft.com",
    "login.live.com", 
    "activation.sls.microsoft.com",
    "crl.microsoft.com",
    "validation.sls.microsoft.com",
    "activation-v2.sls.microsoft.com",
    "validation-v2.sls.microsoft.com",
    "displaycatalog.mp.microsoft.com",
    "licensing.mp.microsoft.com",
    "purchase.mp.microsoft.com",
    "displaycatalog.md.mp.microsoft.com",
    "licensing.md.mp.microsoft.com",
    "purchase.md.mp.microsoft.com"
)

Write-Host "`nErstelle Firewall-Regeln..." -ForegroundColor Yellow

foreach ($domain in $domains) {
    try {
        Write-Host "Blockiere: $domain" -ForegroundColor Cyan
        
        # HTTP blockieren (Port 80)
        New-NetFirewallRule -DisplayName "Block_${domain}_HTTP" -Direction Outbound -Protocol TCP -RemotePort 80 -Action Block -Enabled True
        
        # HTTPS blockieren (Port 443) 
        New-NetFirewallRule -DisplayName "Block_${domain}_HTTPS" -Direction Outbound -Protocol TCP -RemotePort 443 -Action Block -Enabled True
        
        Write-Host "✓ $domain erfolgreich blockiert" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Fehler beim Blockieren von $domain : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Zusätzliche allgemeine Aktivierungsblockade
try {
    Write-Host "`nErstelle zusätzliche Microsoft Activation Blockade..." -ForegroundColor Yellow
    New-NetFirewallRule -DisplayName "Block_MS_Activation_General" -Direction Outbound -Protocol TCP -RemotePort 80,443 -RemoteAddress "*.microsoft.com" -Action Block -Enabled True
    Write-Host "✓ Allgemeine Microsoft Activation Blockade erstellt" -ForegroundColor Green
}
catch {
    Write-Host "✗ Fehler bei allgemeiner Blockade: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🔒 Firewall-Regeln erfolgreich erstellt!" -ForegroundColor Green
Write-Host "Verwende das Entfernungs-Script um die Regeln wieder zu entfernen." -ForegroundColor Yellow

Read-Host "`nDrücke Enter zum Beenden"

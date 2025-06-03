# Proxy und SSL Inspection Test Script
# Testet Proxy-Konfiguration und SSL-Inspection für Microsoft-Endpunkte

# Ausgabedatei definieren
$outputFile = "Proxy_SSL_Test_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$logContent = @()

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "PROXY & SSL INSPECTION TEST" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Ergebnisse werden gespeichert in: $outputFile" -ForegroundColor Yellow
Write-Host ""

$logContent += "============================================="
$logContent += "PROXY & SSL INSPECTION TEST"
$logContent += "============================================="
$logContent += "Test gestartet am: $(Get-Date)"
$logContent += ""

# Test-Endpunkte (alle Microsoft-Endpunkte)
$testEndpoints = @(
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

# 1. PROXY-KONFIGURATION PRÜFEN
Write-Host "1. PROXY-KONFIGURATION PRÜFEN" -ForegroundColor Yellow
Write-Host "==============================" -ForegroundColor Yellow

$logContent += "1. PROXY-KONFIGURATION PRÜFEN"
$logContent += "=============================="

# Environment Variables prüfen
Write-Host "`nUmgebungsvariablen:" -ForegroundColor White
$logContent += ""
$logContent += "Umgebungsvariablen:"

$proxyVars = @("HTTP_PROXY", "HTTPS_PROXY", "http_proxy", "https_proxy", "NO_PROXY", "no_proxy")
foreach ($var in $proxyVars) {
    $value = [Environment]::GetEnvironmentVariable($var)
    if ($value) {
        Write-Host "  $var = $value" -ForegroundColor Green
        $logContent += "  $var = $value"
    } else {
        Write-Host "  $var = <nicht gesetzt>" -ForegroundColor Gray
        $logContent += "  $var = <nicht gesetzt>"
    }
}

# Internet Explorer Proxy Settings
Write-Host "`nInternet Explorer Proxy Settings:" -ForegroundColor White
$logContent += ""
$logContent += "Internet Explorer Proxy Settings:"

try {
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
    $proxyEnable = Get-ItemProperty -Path $regPath -Name "ProxyEnable" -ErrorAction SilentlyContinue
    $proxyServer = Get-ItemProperty -Path $regPath -Name "ProxyServer" -ErrorAction SilentlyContinue
    $proxyOverride = Get-ItemProperty -Path $regPath -Name "ProxyOverride" -ErrorAction SilentlyContinue
    $autoConfigURL = Get-ItemProperty -Path $regPath -Name "AutoConfigURL" -ErrorAction SilentlyContinue
    
    Write-Host "  Proxy aktiviert: $($proxyEnable.ProxyEnable)" -ForegroundColor $(if ($proxyEnable.ProxyEnable -eq 1) { "Red" } else { "Green" })
    $logContent += "  Proxy aktiviert: $($proxyEnable.ProxyEnable)"
    
    if ($proxyServer.ProxyServer) {
        Write-Host "  Proxy Server: $($proxyServer.ProxyServer)" -ForegroundColor Red
        $logContent += "  Proxy Server: $($proxyServer.ProxyServer)"
    }
    
    if ($proxyOverride.ProxyOverride) {
        Write-Host "  Proxy Bypass: $($proxyOverride.ProxyOverride)" -ForegroundColor Yellow
        $logContent += "  Proxy Bypass: $($proxyOverride.ProxyOverride)"
    }
    
    if ($autoConfigURL.AutoConfigURL) {
        Write-Host "  PAC-Datei: $($autoConfigURL.AutoConfigURL)" -ForegroundColor Yellow
        $logContent += "  PAC-Datei: $($autoConfigURL.AutoConfigURL)"
    }
}
catch {
    Write-Host "  Fehler beim Auslesen der Proxy-Einstellungen: $($_.Exception.Message)" -ForegroundColor Red
    $logContent += "  Fehler beim Auslesen der Proxy-Einstellungen: $($_.Exception.Message)"
}

# 2. SSL ZERTIFIKAT ANALYSE
Write-Host "`n`n2. SSL ZERTIFIKAT ANALYSE" -ForegroundColor Yellow
Write-Host "==========================" -ForegroundColor Yellow

$logContent += ""
$logContent += ""
$logContent += "2. SSL ZERTIFIKAT ANALYSE"
$logContent += "=========================="

foreach ($endpoint in $testEndpoints) {
    Write-Host "`nAnalysiere SSL-Zertifikat für: $endpoint" -ForegroundColor White
    $logContent += ""
    $logContent += "Analysiere SSL-Zertifikat für: $endpoint"
    
    try {
        # TCP-Verbindung aufbauen und SSL-Stream erstellen
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($endpoint, 443)
        
        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream())
        $sslStream.AuthenticateAsClient($endpoint)
        
        $cert = $sslStream.RemoteCertificate
        $cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cert)
        
        # Zertifikat-Details ausgeben
        Write-Host "  Subject: $($cert2.Subject)" -ForegroundColor Green
        Write-Host "  Issuer: $($cert2.Issuer)" -ForegroundColor $(if ($cert2.Issuer -like "*Corporate*" -or $cert2.Issuer -like "*Proxy*" -or $cert2.Issuer -like "*Firewall*") { "Red" } else { "Green" })
        Write-Host "  Gültig von: $($cert2.NotBefore)" -ForegroundColor White
        Write-Host "  Gültig bis: $($cert2.NotAfter)" -ForegroundColor White
        Write-Host "  Fingerprint (SHA1): $($cert2.Thumbprint)" -ForegroundColor White
        Write-Host "  Seriennummer: $($cert2.SerialNumber)" -ForegroundColor White
        
        $logContent += "  Subject: $($cert2.Subject)"
        $logContent += "  Issuer: $($cert2.Issuer)"
        $logContent += "  Gültig von: $($cert2.NotBefore)"
        $logContent += "  Gültig bis: $($cert2.NotAfter)"
        $logContent += "  Fingerprint (SHA1): $($cert2.Thumbprint)"
        $logContent += "  Seriennummer: $($cert2.SerialNumber)"
        
        # SSL Inspection Warnung
        if ($cert2.Issuer -like "*Corporate*" -or $cert2.Issuer -like "*Proxy*" -or $cert2.Issuer -like "*Firewall*" -or $cert2.Issuer -like "*Internal*") {
            Write-Host "  ⚠️  WARNUNG: SSL INSPECTION ERKANNT!" -ForegroundColor Red
            Write-Host "      Das Zertifikat wurde möglicherweise durch einen Proxy/Firewall ersetzt." -ForegroundColor Red
            $logContent += "  WARNUNG: SSL INSPECTION ERKANNT!"
            $logContent += "      Das Zertifikat wurde möglicherweise durch einen Proxy/Firewall ersetzt."
        }
        
        $sslStream.Close()
        $tcpClient.Close()
        
    }
    catch {
        Write-Host "  ❌ Fehler bei SSL-Analyse: $($_.Exception.Message)" -ForegroundColor Red
        $logContent += "  Fehler bei SSL-Analyse: $($_.Exception.Message)"
    }
}

# 3. VERBINDUNGSZEIT ANALYSE
Write-Host "`n`n3. VERBINDUNGSZEIT ANALYSE" -ForegroundColor Yellow
Write-Host "===========================" -ForegroundColor Yellow

$logContent += ""
$logContent += ""
$logContent += "3. VERBINDUNGSZEIT ANALYSE"
$logContent += "==========================="

foreach ($endpoint in $testEndpoints) {
    Write-Host "`nMesse Verbindungszeit für: $endpoint" -ForegroundColor White
    $logContent += ""
    $logContent += "Messe Verbindungszeit für: $endpoint"
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $result = Test-NetConnection -ComputerName $endpoint -Port 443 -InformationLevel Quiet
        $stopwatch.Stop()
        
        $responseTime = $stopwatch.ElapsedMilliseconds
        Write-Host "  Verbindungszeit: $responseTime ms" -ForegroundColor $(if ($responseTime -gt 5000) { "Red" } elseif ($responseTime -gt 2000) { "Yellow" } else { "Green" })
        $logContent += "  Verbindungszeit: $responseTime ms"
        
        if ($responseTime -gt 5000) {
            Write-Host "  ⚠️  Sehr langsame Verbindung - möglicherweise Proxy-Verzögerung" -ForegroundColor Red
            $logContent += "  Sehr langsame Verbindung - möglicherweise Proxy-Verzögerung"
        }
        
    }
    catch {
        Write-Host "  ❌ Fehler bei Zeitmessung: $($_.Exception.Message)" -ForegroundColor Red
        $logContent += "  Fehler bei Zeitmessung: $($_.Exception.Message)"
    }
}

# 4. DNS AUFLÖSUNG TEST
Write-Host "`n`n4. DNS AUFLÖSUNG TEST" -ForegroundColor Yellow
Write-Host "=====================" -ForegroundColor Yellow

$logContent += ""
$logContent += ""
$logContent += "4. DNS AUFLÖSUNG TEST"
$logContent += "====================="

foreach ($endpoint in $testEndpoints) {
    Write-Host "`nDNS-Auflösung für: $endpoint" -ForegroundColor White
    $logContent += ""
    $logContent += "DNS-Auflösung für: $endpoint"
    
    try {
        $dnsResult = Resolve-DnsName -Name $endpoint -Type A
        foreach ($record in $dnsResult) {
            if ($record.Type -eq "A") {
                Write-Host "  IP-Adresse: $($record.IPAddress)" -ForegroundColor Green
                $logContent += "  IP-Adresse: $($record.IPAddress)"
            }
        }
    }
    catch {
        Write-Host "  ❌ DNS-Auflösung fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
        $logContent += "  DNS-Auflösung fehlgeschlagen: $($_.Exception.Message)"
    }
}

# 5. EMPFEHLUNGEN UND ZUSAMMENFASSUNG
Write-Host "`n`n5. EMPFEHLUNGEN" -ForegroundColor Yellow
Write-Host "===============" -ForegroundColor Yellow

$logContent += ""
$logContent += ""
$logContent += "5. EMPFEHLUNGEN"
$logContent += "==============="

$recommendations = @(
    "✅ PROXY BYPASS konfigurieren:",
    "   - Fügen Sie alle Microsoft-Endpunkte zur Proxy-Bypass-Liste hinzu",
    "   - Verwenden Sie Wildcards: *.microsoft.com, *.live.com",
    "",
    "✅ SSL INSPECTION ausschließen:",
    "   - Konfigurieren Sie SSL-Inspection-Ausnahmen für Microsoft-Dienste",
    "   - Verwenden Sie Zertifikat-Pinning wo möglich",
    "",
    "✅ FIREWALL-REGELN:",
    "   - Öffnen Sie Port 443 (HTTPS) für alle Microsoft-Endpunkte",
    "   - Erlauben Sie direkten Zugang ohne Proxy-Umleitung",
    "",
    "✅ MONITORING:",
    "   - Überwachen Sie Verbindungszeiten regelmäßig",
    "   - Implementieren Sie Alerting bei SSL-Inspection-Erkennungen"
)

foreach ($rec in $recommendations) {
    Write-Host $rec -ForegroundColor White
    $logContent += $rec
}

Write-Host "`nTest abgeschlossen um: $(Get-Date)" -ForegroundColor Cyan
$logContent += ""
$logContent += "Test abgeschlossen um: $(Get-Date)"

# Ausgabe in TXT-Datei schreiben
try {
    $logContent | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Host "`n✅ Ergebnisse erfolgreich gespeichert in: $outputFile" -ForegroundColor Green
}
catch {
    Write-Host "`n❌ Fehler beim Speichern der Datei: $($_.Exception.Message)" -ForegroundColor Red
}

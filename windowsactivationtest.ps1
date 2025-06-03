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
    
    # Methode 1: Direkte SSL-Stream Verbindung
    try {
        # TLS-Protokoll explizit setzen
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
        
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.ReceiveTimeout = 10000
        $tcpClient.SendTimeout = 10000
        $tcpClient.Connect($endpoint, 443)
        
        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, ({$true}))
        $sslStream.AuthenticateAsClient($endpoint)
        
        $cert = $sslStream.RemoteCertificate
        $cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($cert)
        
        # Zertifikat-Details ausgeben
        Write-Host "  ✅ SSL-Verbindung erfolgreich" -ForegroundColor Green
        Write-Host "  Subject: $($cert2.Subject)" -ForegroundColor Green
        Write-Host "  Issuer: $($cert2.Issuer)" -ForegroundColor $(if ($cert2.Issuer -like "*Corporate*" -or $cert2.Issuer -like "*Proxy*" -or $cert2.Issuer -like "*Firewall*") { "Red" } else { "Green" })
        Write-Host "  Gültig von: $($cert2.NotBefore)" -ForegroundColor White
        Write-Host "  Gültig bis: $($cert2.NotAfter)" -ForegroundColor White
        Write-Host "  Fingerprint (SHA1): $($cert2.Thumbprint)" -ForegroundColor White
        Write-Host "  Seriennummer: $($cert2.SerialNumber)" -ForegroundColor White
        
        $logContent += "  SSL-Verbindung erfolgreich"
        $logContent += "  Subject: $($cert2.Subject)"
        $logContent += "  Issuer: $($cert2.Issuer)"
        $logContent += "  Gültig von: $($cert2.NotBefore)"
        $logContent += "  Gültig bis: $($cert2.NotAfter)"
        $logContent += "  Fingerprint (SHA1): $($cert2.Thumbprint)"
        $logContent += "  Seriennummer: $($cert2.SerialNumber)"
        
        # SSL Inspection Warnung - KORRIGIERTE ERKENNUNG
        $suspiciousCAs = @(
            "*Corporate*", "*Proxy*", "*Firewall*", "*Internal*", 
            "*Company*", "*Enterprise*", "*Organization*", "*Org*",
            "*ZScaler*", "*Fortinet*", "*SonicWall*", "*Checkpoint*",
            "*Palo Alto*", "*Symantec*Proxy*", "*BlueCoat*", "*McAfee*Web*"
        )
        
        $isSslInspection = $false
        foreach ($pattern in $suspiciousCAs) {
            if ($cert2.Issuer -like $pattern) {
                $isSslInspection = $true
                break
            }
        }
        
        # Legitime CAs NICHT als SSL Inspection melden
        $legitimateCAs = @(
            "*Microsoft*", "*DigiCert*", "*VeriSign*", "*Symantec*", 
            "*GeoTrust*", "*Thawte*", "*GlobalSign*", "*Entrust*",
            "*Let's Encrypt*", "*Amazon*", "*Google*", "*Akamai*"
        )
        
        foreach ($legit in $legitimateCAs) {
            if ($cert2.Issuer -like $legit) {
                $isSslInspection = $false
                break
            }
        }
        
        if ($isSslInspection) {
            Write-Host "  ⚠️  WARNUNG: SSL INSPECTION ERKANNT!" -ForegroundColor Red
            Write-Host "      Das Zertifikat wurde durch einen Proxy/Firewall ersetzt." -ForegroundColor Red
            $logContent += "  WARNUNG: SSL INSPECTION ERKANNT!"
            $logContent += "      Das Zertifikat wurde durch einen Proxy/Firewall ersetzt."
        } else {
            Write-Host "  ✅ Legitimes Zertifikat von vertrauenswürdiger CA" -ForegroundColor Green
            $logContent += "  Legitimes Zertifikat von vertrauenswürdiger CA"
        }
        
        $sslStream.Close()
        $tcpClient.Close()
        
    }
    catch [System.Security.Authentication.AuthenticationException] {
        Write-Host "  ❌ SSL-Authentifizierung fehlgeschlagen: SSPI-Problem!" -ForegroundColor Red
        Write-Host "      Details: $($_.Exception.Message)" -ForegroundColor Red
        $logContent += "  SSL-Authentifizierung fehlgeschlagen: SSPI-Problem!"
        $logContent += "      Details: $($_.Exception.Message)"
        
        # Diagnose-Schritte für SSPI-Fehler
        Write-Host "  🔍 Diagnose-Schritte:" -ForegroundColor Yellow
        $logContent += "  Diagnose-Schritte:"
        
        # Teste ob Endpunkt erreichbar ist
        try {
            $pingTest = Test-NetConnection -ComputerName $endpoint -Port 443 -InformationLevel Quiet
            if ($pingTest) {
                Write-Host "    ✅ Port 443 ist erreichbar" -ForegroundColor Green
                $logContent += "    Port 443 ist erreichbar"
                
                # Versuche Invoke-WebRequest mit verschiedenen TLS-Versionen
                Write-Host "    🔄 Teste verschiedene TLS-Versionen..." -ForegroundColor Yellow
                $logContent += "    Teste verschiedene TLS-Versionen..."
                
                # TLS 1.2
                try {
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                    $webTest = Invoke-WebRequest -Uri "https://$endpoint" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
                    Write-Host "    ✅ TLS 1.2 erfolgreich" -ForegroundColor Green
                    $logContent += "    TLS 1.2 erfolgreich"
                }
                catch {
                    Write-Host "    ❌ TLS 1.2 fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
                    $logContent += "    TLS 1.2 fehlgeschlagen: $($_.Exception.Message)"
                }
                
                # TLS 1.3 (falls verfügbar)
                try {
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls13
                    $webTest = Invoke-WebRequest -Uri "https://$endpoint" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
                    Write-Host "    ✅ TLS 1.3 erfolgreich" -ForegroundColor Green
                    $logContent += "    TLS 1.3 erfolgreich"
                }
                catch {
                    Write-Host "    ❌ TLS 1.3 fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
                    $logContent += "    TLS 1.3 fehlgeschlagen: $($_.Exception.Message)"
                }
            } else {
                Write-Host "    ❌ Port 443 nicht erreichbar - Firewall/Proxy-Blockierung" -ForegroundColor Red
                $logContent += "    Port 443 nicht erreichbar - Firewall/Proxy-Blockierung"
            }
        }
        catch {
            Write-Host "    ❌ Netzwerktest fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
            $logContent += "    Netzwerktest fehlgeschlagen: $($_.Exception.Message)"
        }
    }
    catch [System.ComponentModel.Win32Exception] {
        $errorCode = $_.Exception.NativeErrorCode
        Write-Host "  ❌ SSPI-Fehler (Win32Exception): $errorCode" -ForegroundColor Red
        Write-Host "      Details: $($_.Exception.Message)" -ForegroundColor Red
        
        $logContent += "  SSPI-Fehler (Win32Exception): $errorCode"
        $logContent += "      Details: $($_.Exception.Message)"
        
        # Spezifische SSPI Error Code Diagnose
        switch ($errorCode) {
            -2146893016 { # 0x80090308 = SEC_E_INVALID_TOKEN
                Write-Host "      🔍 Diagnose: Ungültiges SSL-Token - möglicherweise SSL Inspection" -ForegroundColor Yellow
                $logContent += "      Diagnose: Ungültiges SSL-Token - möglicherweise SSL Inspection"
            }
            -2146893019 { # 0x80090305 = SEC_E_TARGET_UNKNOWN  
                Write-Host "      🔍 Diagnose: Unbekanntes Ziel - DNS oder Proxy-Problem" -ForegroundColor Yellow
                $logContent += "      Diagnose: Unbekanntes Ziel - DNS oder Proxy-Problem"
            }
            -2146893022 { # 0x80090302 = SEC_E_UNSUPPORTED_FUNCTION
                Write-Host "      🔍 Diagnose: Nicht unterstützte SSL-Funktion - TLS-Version Problem" -ForegroundColor Yellow
                $logContent += "      Diagnose: Nicht unterstützte SSL-Funktion - TLS-Version Problem"
            }
            -2146893017 { # 0x80090307 = SEC_E_NO_AUTHENTICATING_AUTHORITY
                Write-Host "      🔍 Diagnose: Keine vertrauenswürdige CA - SSL Inspection oder Zertifikatsproblem" -ForegroundColor Yellow
                $logContent += "      Diagnose: Keine vertrauenswürdige CA - SSL Inspection oder Zertifikatsproblem"
            }
            default {
                Write-Host "      🔍 Diagnose: Unbekannter SSPI-Fehler - überprüfen Sie SSL Inspection und Proxy-Konfiguration" -ForegroundColor Yellow
                $logContent += "      Diagnose: Unbekannter SSPI-Fehler - überprüfen Sie SSL Inspection und Proxy-Konfiguration"
            }
        }
        
        # Alternative Testmethode mit deaktivierter Zertifikatsprüfung
        try {
            Write-Host "  🔄 Teste ohne Zertifikatsprüfung..." -ForegroundColor Yellow
            
            # Zertifikatsprüfung temporär deaktivieren
            $originalCallback = [Net.ServicePointManager]::ServerCertificateValidationCallback
            [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
            
            $webRequest = Invoke-WebRequest -Uri "https://$endpoint" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            Write-Host "  ✅ Verbindung ohne Zertifikatsprüfung erfolgreich - SSL Inspection bestätigt!" -ForegroundColor Red
            $logContent += "  Verbindung ohne Zertifikatsprüfung erfolgreich - SSL Inspection bestätigt!"
            
            # Callback zurücksetzen
            [Net.ServicePointManager]::ServerCertificateValidationCallback = $originalCallback
        }
        catch {
            Write-Host "  ❌ Auch ohne Zertifikatsprüfung fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Red
            $logContent += "  Auch ohne Zertifikatsprüfung fehlgeschlagen: $($_.Exception.Message)"
            
            # Callback zurücksetzen
            [Net.ServicePointManager]::ServerCertificateValidationCallback = $originalCallback
        }
    }
    catch {
        Write-Host "  ❌ Allgemeiner Fehler: $($_.Exception.GetType().Name)" -ForegroundColor Red
        Write-Host "      Details: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.InnerException) {
            Write-Host "      Inner Exception: $($_.Exception.InnerException.Message)" -ForegroundColor Red
            $logContent += "      Inner Exception: $($_.Exception.InnerException.Message)"
        }
        $logContent += "  Allgemeiner Fehler: $($_.Exception.GetType().Name)"
        $logContent += "      Details: $($_.Exception.Message)"
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

# Test-NetConnection Script für Microsoft Endpunkte
# Testet die Konnektivität zu allen benötigten Microsoft-Diensten

# Ausgabedatei definieren
$outputFile = "Microsoft_Endpoints_Test_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$logContent = @()

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Microsoft Endpunkte Konnektivitätstest" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Ergebnisse werden gespeichert in: $outputFile" -ForegroundColor Yellow
Write-Host ""

$logContent += "=========================================="
$logContent += "Microsoft Endpunkte Konnektivitätstest"
$logContent += "=========================================="
$logContent += "Test gestartet am: $(Get-Date)"
$logContent += ""

# Liste der zu testenden Microsoft-Endpunkte
$endpoints = @(
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

# Ergebnis-Arrays für Zusammenfassung
$successfulConnections = @()
$failedConnections = @()

Write-Host "Teste Verbindungen zu Microsoft-Endpunkten..." -ForegroundColor Yellow
Write-Host ""

$logContent += "Teste Verbindungen zu Microsoft-Endpunkten..."
$logContent += ""

foreach ($endpoint in $endpoints) {
    Write-Host "Teste: $endpoint" -ForegroundColor White -NoNewline
    
    try {
        $result = Test-NetConnection -ComputerName $endpoint -Port 443 -InformationLevel Quiet -WarningAction SilentlyContinue
        
        if ($result) {
            Write-Host " ✅ ERFOLGREICH" -ForegroundColor Green
            $successfulConnections += $endpoint
            $logContent += "Teste: $endpoint - ERFOLGREICH"
        } else {
            Write-Host " ❌ FEHLGESCHLAGEN" -ForegroundColor Red
            $failedConnections += $endpoint
            $logContent += "Teste: $endpoint - FEHLGESCHLAGEN"
        }
    }
    catch {
        Write-Host " ❌ FEHLER: $($_.Exception.Message)" -ForegroundColor Red
        $failedConnections += $endpoint
        $logContent += "Teste: $endpoint - FEHLER: $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "ZUSAMMENFASSUNG" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$logContent += ""
$logContent += "=========================================="
$logContent += "ZUSAMMENFASSUNG"
$logContent += "=========================================="

Write-Host "Erfolgreich getestet: $($successfulConnections.Count)/$($endpoints.Count)" -ForegroundColor Green
Write-Host "Fehlgeschlagen: $($failedConnections.Count)/$($endpoints.Count)" -ForegroundColor $(if ($failedConnections.Count -eq 0) { "Green" } else { "Red" })

$logContent += "Erfolgreich getestet: $($successfulConnections.Count)/$($endpoints.Count)"
$logContent += "Fehlgeschlagen: $($failedConnections.Count)/$($endpoints.Count)"

if ($successfulConnections.Count -gt 0) {
    Write-Host ""
    Write-Host "✅ ERFOLGREICHE VERBINDUNGEN:" -ForegroundColor Green
    $logContent += ""
    $logContent += "ERFOLGREICHE VERBINDUNGEN:"
    foreach ($success in $successfulConnections) {
        Write-Host "   - $success" -ForegroundColor White
        $logContent += "   - $success"
    }
}

if ($failedConnections.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ FEHLGESCHLAGENE VERBINDUNGEN:" -ForegroundColor Red
    $logContent += ""
    $logContent += "FEHLGESCHLAGENE VERBINDUNGEN:"
    foreach ($failed in $failedConnections) {
        Write-Host "   - $failed" -ForegroundColor White
        $logContent += "   - $failed"
    }
    Write-Host ""
    Write-Host "EMPFEHLUNG:" -ForegroundColor Yellow
    Write-Host "- Überprüfen Sie Firewall-Regeln für Port 443 (HTTPS)" -ForegroundColor White
    Write-Host "- Konfigurieren Sie Proxy-Bypass für diese Endpunkte" -ForegroundColor White
    Write-Host "- Stellen Sie sicher, dass DNS-Auflösung funktioniert" -ForegroundColor White
    
    $logContent += ""
    $logContent += "EMPFEHLUNG:"
    $logContent += "- Überprüfen Sie Firewall-Regeln für Port 443 (HTTPS)"
    $logContent += "- Konfigurieren Sie Proxy-Bypass für diese Endpunkte"
    $logContent += "- Stellen Sie sicher, dass DNS-Auflösung funktioniert"
}

Write-Host ""
Write-Host "Test abgeschlossen um: $(Get-Date)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

$logContent += ""
$logContent += "Test abgeschlossen um: $(Get-Date)"
$logContent += "=========================================="

# Optional: Detaillierte Ausgabe für fehlgeschlagene Verbindungen
if ($failedConnections.Count -gt 0) {
    Write-Host ""
    $detailTest = Read-Host "Möchten Sie eine detaillierte Analyse für fehlgeschlagene Verbindungen durchführen? (j/n)"
    
    if ($detailTest -eq "j" -or $detailTest -eq "J" -or $detailTest -eq "ja") {
        Write-Host ""
        Write-Host "DETAILLIERTE ANALYSE:" -ForegroundColor Yellow
        Write-Host "=====================" -ForegroundColor Yellow
        
        $logContent += ""
        $logContent += "DETAILLIERTE ANALYSE:"
        $logContent += "====================="
        
        foreach ($failed in $failedConnections) {
            Write-Host ""
            Write-Host "Analysiere: $failed" -ForegroundColor White
            $logContent += ""
            $logContent += "Analysiere: $failed"
            try {
                $detailResult = Test-NetConnection -ComputerName $failed -Port 443
                Write-Host "Ping erfolgreich: $($detailResult.PingSucceeded)" -ForegroundColor White
                Write-Host "Namensauflösung: $($detailResult.NameResolutionSucceeded)" -ForegroundColor White
                Write-Host "TCP-Test (Port 443): $($detailResult.TcpTestSucceeded)" -ForegroundColor White
                
                $logContent += "Ping erfolgreich: $($detailResult.PingSucceeded)"
                $logContent += "Namensauflösung: $($detailResult.NameResolutionSucceeded)"
                $logContent += "TCP-Test (Port 443): $($detailResult.TcpTestSucceeded)"
            }
            catch {
                Write-Host "Fehler bei detaillierter Analyse: $($_.Exception.Message)" -ForegroundColor Red
                $logContent += "Fehler bei detaillierter Analyse: $($_.Exception.Message)"
            }
        }
    }
}

# Ausgabe in TXT-Datei schreiben
try {
    $logContent | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Host ""
    Write-Host "✅ Ergebnisse erfolgreich gespeichert in: $outputFile" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "❌ Fehler beim Speichern der Datei: $($_.Exception.Message)" -ForegroundColor Red
}

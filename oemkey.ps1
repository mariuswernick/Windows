# Your existing script (the one from previous message)
try {
    $originalKey = (Get-CimInstance -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey

    if (-not $originalKey) {
        Write-Output "ERROR: No OEM key found on this device"
        exit 1
    }

    Write-Output "REMEDIATION: Switching to OEM key ending in: $($originalKey.Substring($originalKey.Length-5))"

    # Remove current license
    $result = Start-Process -FilePath "cscript.exe" -ArgumentList "//nologo C:\Windows\System32\slmgr.vbs /upk" -Wait -WindowStyle Hidden -PassThru
    Start-Sleep -Seconds 5

    # Install OEM key
    $result = Start-Process -FilePath "cscript.exe" -ArgumentList "//nologo C:\Windows\System32\slmgr.vbs /ipk $originalKey" -Wait -WindowStyle Hidden -PassThru
    Start-Sleep -Seconds 5

    # Activate
    $result = Start-Process -FilePath "cscript.exe" -ArgumentList "//nologo C:\Windows\System32\slmgr.vbs /ato" -Wait -WindowStyle Hidden -PassThru
    Start-Sleep -Seconds 15

    # Verify
    $licenseInfo = Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | where { $_.PartialProductKey }
    
    if ($licenseInfo.LicenseStatus -eq 1) {
        Write-Output "SUCCESS: Remediated to OEM licensing"
        exit 0
    } else {
        Write-Output "WARNING: Remediation completed but activation pending"
        exit 0
    }

} catch {
    Write-Output "ERROR: Remediation failed: $($_.Exception.Message)"
    exit 1
}

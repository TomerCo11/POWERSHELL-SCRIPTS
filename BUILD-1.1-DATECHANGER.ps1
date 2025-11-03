# ==========================================
#  Masofon SFR Remote Editor - Build 1.1
# ==========================================

# Step 0: Import credentials from XML
$credFile = "$ENV:USERPROFILE\mysecurecred.xml"  # <-- update XML file name
if (!(Test-Path $credFile)) {
    Write-Host "❌ Credential file not found at $credFile" -ForegroundColor Red
    exit
}
$cred = Import-Clixml -Path $credFile

# Step 1: Ask for branch number
$bn = Read-Host "Enter the 3-digit branch number"

# Step 2: Ask for remote computer name
$remoteComputer = Read-Host "Enter the remote computer name"

# Step 3: Run the update remotely
Invoke-Command -ComputerName $remoteComputer -Credential $cred -ScriptBlock {
    param($branchNumber)

    $filePath = "C:\Masofon\datafiles\date$branchNumber.sfr"

    if (Test-Path $filePath) {
        Write-Host "✅ File found at $filePath" -ForegroundColor Green

        # Ask user for new number/date
        $date = Read-Host "Enter the new number/date to update in the file"

        try {
            # Read file contents
            $content = Get-Content $filePath -Raw

            # Replace all digits in the file with the new input
            $newContent = $content -replace '\d+', $date

            # Save updated file
            Set-Content -Path $filePath -Value $newContent -Force

            # Verify update
            if ($newContent -match $date) {
                Write-Host "✅ Date/number successfully updated to $date for branch $branchNumber" -ForegroundColor Green
                Start-Sleep -Seconds 3
            } else {
                Write-Host "❌ Failed to update date/number inside file." -ForegroundColor Red
                Start-Sleep -Seconds 5
            }
        }
        catch {
            Write-Host "❌ Error while editing file: $($_.Exception.Message)" -ForegroundColor Red
            Start-Sleep -Seconds 5
        }
    }
    else {
        Write-Host "❌ File not found at: $filePath" -ForegroundColor Red
        Start-Sleep -Seconds 5
    }

} -ArgumentList $bn

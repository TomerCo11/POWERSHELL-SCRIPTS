# ==========================================
#  Masofon SFR Automated Remote Editor - Build 1.2
# ==========================================

# Step 0: Import credentials from XML
$credFile = "$ENV:USERPROFILE\mysecurecreds.xml"  # <-- update XML file name
if (!(Test-Path $credFile)) {
    Write-Host "❌ Credential file not found at $credFile" -ForegroundColor Red
    exit
}
$cred = Import-Clixml -Path $credFile

# Step 1: Ask for path to computer list
$listPath = Read-Host "Enter the path to the computer list file"
if (!(Test-Path $listPath)) {
    Write-Host "❌ Computer list file not found at $listPath" -ForegroundColor Red
    exit
}

# Step 2: Ask for the new number/date to update in all files
$newNumber = Read-Host "Enter the new number/date to update in the files"

# Step 3: Read each computer from the list
$computers = Get-Content $listPath

foreach ($comp in $computers) {
    # Extract branch number from computer name format: WKS-<branch>-<id>
    if ($comp -match 'WKS-(\d+)-\d+') {
        $branchNumber = $matches[1]
    } else {
        Write-Host "❌ Could not parse branch number from $comp" -ForegroundColor Red
        Start-Sleep -Seconds 5
        continue
    }

    Write-Host "🔹 Processing $comp (Branch $branchNumber)..."

    try {
        # Remote execution using imported credentials
        Invoke-Command -ComputerName $comp -Credential $cred -ScriptBlock {
            param($branchNumber, $newNumber)

            $filePath = "C:\Masofon\datafiles\date$branchNumber.sfr"

            if (Test-Path $filePath) {
                Write-Host "✅ File found at $filePath" -ForegroundColor Green

                # Read file content
                $content = Get-Content $filePath -Raw

                # Replace all digits with new number/date
                $newContent = $content -replace '\d+', $newNumber

                # Save updated file
                Set-Content -Path $filePath -Value $newContent -Force

                # Verify update
                if ($newContent -match $newNumber) {
                    Write-Host "✅ Successfully updated to $newNumber" -ForegroundColor Green
                    Start-Sleep -Seconds 3
                } else {
                    Write-Host "❌ Failed to update file content" -ForegroundColor Red
                    Start-Sleep -Seconds 5
                }
            }
            else {
                Write-Host "❌ File not found at: $filePath" -ForegroundColor Red
                Start-Sleep -Seconds 5
            }
        } -ArgumentList $branchNumber, $newNumber
    }
    catch {
        Write-Host "❌ Error connecting to $comp: $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep -Seconds 5
    }
}

Write-Host "🏁 Build 1.2 processing complete for all computers in the list."

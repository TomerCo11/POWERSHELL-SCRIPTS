Import-Module ActiveDirectory

# Flash ASCII logo
$flashLogo = @"
 ___      ___ ________   ________     
|\  \    /  /|\   ___  \|\   ____\    
\ \  \  /  / | \  \\ \  \ \  \___|    
 \ \  \/  / / \ \  \\ \  \ \  \       
  \ \    / /   \ \  \\ \  \ \  \____  
   \ \__/ /     \ \__\\ \__\ \_______\
    \|__|/       \|__| \|__|\|_______|   
"@

# VNC configuration
$vncPort = 5900
$vncPassword = "QWErty12"
$logFile = "C:\Install\HelpDeskBranchLog.txt"
$launchScript = "C:\Install\VNC-KUPOT\LaunchVNC.ps1"

# Import high-permission credentials
$credPath = "$env:USERPROFILE\mysecurecred.xml"
if (Test-Path $credPath) {
    $cred = Import-Clixml $credPath
    Write-Host "✅ Credentials successfully imported!" -ForegroundColor Green
    $credUser = $cred.UserName
} else {
    Write-Host "❌ Credential file not found: $credPath" -ForegroundColor Red
    exit
}

# Function to connect to a Kupa using external VNC launcher and ping both POS and EMV



function Connect-Kupa {
    param($branch)

    while ($true) {
        $kupa = Read-Host "Enter Kupa number (or 0 to change branch)"
        if ($kupa -eq "0") { return "back" }
        if ($kupa -notmatch '^\d+$') {
            Write-Host "❌ Kupa must be numeric!" -ForegroundColor Red
            continue
        }

        # Split branch
        $s1 = $branch.Substring(0,1)              # first digit
        $s2 = [int]$branch.Substring(1,2)         # last two digits, as INT to drop leading zeros

        # Octets
        $posOctet = 10 + [int]$kupa
        $emvOctet = 150 + [int]$kupa

        # Keep "1$s1" for the second octet (e.g., 609 -> 16; 022 -> 10; 001 -> 10)
        $secondOctet = "1$s1"

        # ✅ Build IPs: third octet is INT (no leading zero)
        $posIP = "10.{0}.{1}.{2}" -f $secondOctet, $s2, $posOctet
        $emvIP = "10.{0}.{1}.{2}" -f $secondOctet, $s2, $emvOctet

        # DNS name still uses 3-digit branch and 2-digit kupa
        $dnsName = "pos-$branch-{0:D2}" -f [int]$kupa

        #Write-Host "🔍 DNS Name: $dnsName"
        #Write-Host "📡 POS IP: $posIP"
        #Write-Host "💳 EMV IP: $emvIP"

        # Open ping windows (EMV)
        #Start-Process "cmd.exe" -ArgumentList "/k ping -t $emvIP"

        # VNC connection
        Write-Host "🔍 Pinging $posIP ..."
        if (Test-Connection -ComputerName $posIP -Count 1 -Quiet) {
            Write-Host "✅ POS is online, launching VNC..." -ForegroundColor Green
            Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$launchScript`" -ip `"$posIP`" -port $vncPort -password `"$vncPassword`"" -WindowStyle Hidden
        } else {
            Write-Host "❌ POS IP is not responding to ping." -ForegroundColor Red
        }
    }
}




# Main loop
$lastBranch = $null
while ($true) {
    Clear-Host
    Write-Host $flashLogo -ForegroundColor Yellow
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host "      HelpDesk POS Tool        " -ForegroundColor Blue
    Write-Host "===============================" -ForegroundColor Cyan
    Write-Host "========Made By TomerCo========" -ForegroundColor Blue
    Write-Host "Hello ${credUser}! Enjoy working with this!" -ForegroundColor Green
    Write-Host "===============================" -ForegroundColor Cyan

    $branchInput = Read-Host "Enter Branch number (3 digits) or N to quit"
   
    if ($branchInput -match '^[Nn]$') { exit }

    if ([string]::IsNullOrWhiteSpace($branchInput)) {
        if ($lastBranch) {
            $branch = $lastBranch
            Write-Host "🔄 Using last branch: ${branch}" -ForegroundColor Cyan
        } else {
            Write-Host "❌ No previous branch stored!" -ForegroundColor Red
            continue
        }
    }
    elseif ($branchInput -notmatch '^\d{3}$') {
        Write-Host "❌ Branch must be exactly 3 digits!" -ForegroundColor Red
        continue
    } else {
        $branch = $branchInput
    }

    $lastBranch = $branch

    $computers = Get-ADComputer -Filter "Name -like 'pos-$branch-*'" `
                 -Server "posprod.supersol.co.il" -Credential $cred |
                 Select-Object -ExpandProperty Name

    if (-not $computers) {
        Write-Host "⚠️ No computers found for branch ${branch}" -ForegroundColor Yellow
        continue
    }

    $computers | Out-File -FilePath $logFile -Encoding UTF8
    Write-Host "📝 Computers logged to: $logFile" -ForegroundColor Cyan

    Write-Host "💻 Computers in branch ${branch}:" -ForegroundColor Green
    $computers | ForEach-Object { Write-Host " - $_" }

    Connect-Kupa -branch $branch
}

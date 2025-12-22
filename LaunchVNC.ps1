param (
    [string]$ip,
    [int]$port = 5900,
    [string]$password = "QWErty12"
)

$vncPath = "C:\Program Files (x86)\IT Remote Control\vncviewer.exe"
$connect = "/connect $ip::$port /password $password /scale 1.0"

$cmd = "`"$vncPath`" $connect"
cmd.exe /c $cmd

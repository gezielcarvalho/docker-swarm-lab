# WSL2 Port Forwarding Script for Docker Swarm Lab
# Run this in PowerShell as Administrator to access services via localhost on Windows

$ports = @(5000, 8080, 9000, 9001, 9002)
$wslIp = (wsl ip addr show eth0 | Select-String 'inet\s' | ForEach-Object { $_.ToString().Trim().Split()[1].Split('/')[0] })

Write-Host "WSL IP: $wslIp" -ForegroundColor Green

foreach ($port in $ports) {
    Write-Host "Forwarding localhost:$port -> WSL $wslIp`:$port" -ForegroundColor Cyan
    netsh interface portproxy add v4tov4 listenport=$port listenaddress=0.0.0.0 connectport=$port connectaddress=$wslIp
}

Write-Host "`nPort forwarding configured! Services accessible at:" -ForegroundColor Green
Write-Host "  Registry:      http://localhost:5000" -ForegroundColor Yellow
Write-Host "  Jenkins:       http://localhost:8080" -ForegroundColor Yellow
Write-Host "  Portainer DEV: http://localhost:9000" -ForegroundColor Yellow
Write-Host "  Portainer QA:  http://localhost:9001" -ForegroundColor Yellow
Write-Host "  Portainer PROD: http://localhost:9002" -ForegroundColor Yellow

Write-Host "`nTo remove port forwarding later, run:" -ForegroundColor Cyan
Write-Host "  netsh interface portproxy reset" -ForegroundColor White

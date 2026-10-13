# Sends requests to the app (port-forwarded to localhost:18080) so Grafana has data.
# Use -Errors to also hit a missing page and create 404s.
param([int]$Count = 300, [switch]$Errors)
for ($i = 1; $i -le $Count; $i++) {
  try { Invoke-RestMethod "http://localhost:18080/add?a=$i&b=2" | Out-Null } catch {}
  if ($Errors) { try { Invoke-RestMethod "http://localhost:18080/nope" | Out-Null } catch {} }
  Start-Sleep -Milliseconds 100
}
Write-Host "sent $Count requests"

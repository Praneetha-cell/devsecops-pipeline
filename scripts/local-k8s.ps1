# Run from the project folder in PowerShell:  .\scripts\local-k8s.ps1
# Needs: Docker Desktop running, kind, kubectl, helm installed, image devsecops-app:local built.
$ErrorActionPreference = "Continue"   # native tools print harmless text to stderr; Run() checks real exit codes
function Run($c) { Write-Host ">> $c" -ForegroundColor Cyan; Invoke-Expression $c; if ($LASTEXITCODE -ne 0) { throw "Failed: $c" } }

Run "docker build -t devsecops-app:local ."
if (-not ((kind get clusters 2>&1 | Out-String) -match "devsecops")) { Run "kind create cluster --name devsecops" }
Run "kind load docker-image devsecops-app:local --name devsecops"

Run "kubectl apply -f k8s/namespace.yaml"
(Get-Content k8s/deployment.yaml) -replace "IMAGE_PLACEHOLDER", "devsecops-app:local" | kubectl apply -f -
# imagePullPolicy: local image must not be pulled from the internet
kubectl -n devsecops patch deployment devsecops-app --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"Never"}]'
Run "kubectl apply -f k8s/service.yaml -f k8s/networkpolicy.yaml"   # HPA skipped: kind has no metrics-server
Run "kubectl -n devsecops rollout status deployment/devsecops-app --timeout=180s"

Run "helm repo add prometheus-community https://prometheus-community.github.io/helm-charts"
Run "helm repo update"
Run "helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace -f monitoring/kind-values.yaml --wait --timeout 10m"
Run "kubectl apply -f monitoring/app-monitoring.yaml -f monitoring/grafana-dashboard.yaml"
Write-Host "DONE. Next: open 2 more PowerShell windows and run the port-forward commands from the guide." -ForegroundColor Green

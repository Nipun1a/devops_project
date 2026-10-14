# Prometheus and Grafana

Installed on 14 October 2026 in `three-tier-k8s-eks-cluster`, region `ap-south-1`.
Helm release `stable`, namespace `monitoring`, kube-prometheus-stack chart 92.3.1.

## Access

- Grafana: http://k8s-monitori-stablegr-eb3df2eb7e-77cba33b1c17bc54.elb.ap-south-1.amazonaws.com
- Prometheus: http://k8s-monitori-stableku-35ee4bd45e-fc4b12a5e729c3b7.elb.ap-south-1.amazonaws.com

Both use HTTP port 80. Network access is restricted to `38.254.174.214/32`.
If your public IP changes, update both `loadBalancerSourceRanges` in
`monitoring-values.yaml` and reapply the Helm release. Do not expose the
unauthenticated Prometheus endpoint to the whole internet.

Grafana username: `admin`. A random password is stored in the Kubernetes Secret
`monitoring-grafana-admin`, rather than in Git or the Helm values file. Retrieve
it from the repository root in PowerShell:

```powershell
$encoded = kubectl --kubeconfig devops_project/eks/kubeconfig get secret monitoring-grafana-admin -n monitoring -o jsonpath='{.data.admin-password}'
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded))
```

For local access independent of the load balancers, run these in separate
terminals and keep the terminals open:

```powershell
kubectl --kubeconfig devops_project/eks/kubeconfig port-forward -n monitoring svc/stable-grafana 3000:80
kubectl --kubeconfig devops_project/eks/kubeconfig port-forward -n monitoring svc/stable-kube-prometheus-sta-prometheus 9090:80
```

Then browse http://localhost:3000 and http://localhost:9090.

## Configuration and verification

`monitoring-values.yaml` sets limited resource requests/limits for the two
t3.small nodes, a one-day Prometheus retention period with a 2 GB size cap,
and 60-second scraping. Unavailable EKS managed control-plane endpoints are
disabled. Grafana is provisioned with a working Prometheus data source and
25 dashboards. All seven monitoring pods passed readiness checks, and both
external health endpoints were verified. Node memory usage was about 58-64%
during initial installation; leave room for application workloads.

This learning installation uses ephemeral storage. Recreating Prometheus or
Grafana pods can lose metric history or UI-created settings/dashboards. Chart-
provisioned dashboards and the admin Secret remain. Configure persistent storage
before relying on retained data.

Two internet-facing Network Load Balancers provide access, with cross-zone
forwarding for the single-replica services. NLB hours, capacity usage, public IPv4
and any applicable transfer charges consume additional AWS credits. No worker
nodes were added or resized.

From the repository root, reapply using:

```powershell
& ./devops_project/eks/tools/windows-amd64/helm.exe upgrade --install stable prometheus-community/kube-prometheus-stack --version 92.3.1 --namespace monitoring --kubeconfig devops_project/eks/kubeconfig --values devops_project/eks/monitoring-values.yaml --wait --timeout 10m
kubectl --kubeconfig devops_project/eks/kubeconfig get pods,svc -n monitoring
```

The chart includes Prometheus Operator, Prometheus, Grafana, Alertmanager,
kube-state-metrics, node exporters, and provisioned Kubernetes dashboards.
Alertmanager is installed but no email/chat notification receiver is configured.

To remove monitoring when finished, uninstall the `stable` Helm release while
the AWS Load Balancer Controller is still running, then verify that both NLBs
and their related resources were deleted. Helm leaves CRDs and the separately
created admin Secret behind; preserve any needed data before cleanup.

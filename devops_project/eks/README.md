# EKS learning cluster

Deployment approved on 14 October 2026: two t3.small managed worker nodes.
Cluster name: `three-tier-k8s-eks-cluster`. Region: `ap-south-1` (Mumbai).
Deployment completed successfully. Both workers were Ready on Kubernetes
v1.36.4-eks-3b4a6ca. VPC CNI, CoreDNS, kube-proxy, and metrics-server pods passed
the readiness check. The managed node group is ACTIVE with no health issues.

AWS Load Balancer Controller v3.6.0 is also installed with two replicas and an
OIDC-backed IAM service account. See [setup commands](LOAD-BALANCER-CONTROLLER.md).
Prometheus and Grafana are installed in `monitoring`; see [access details](MONITORING.md).

The proposed config uses Mumbai (ap-south-1), two t3.small managed workers,
20 GB gp3 per worker, and public worker networking without a NAT gateway.
Kubernetes 1.36 was returned as the default STANDARD_SUPPORT version by EKS
on 14 October 2026. Validate this config with the installed eksctl before use.

AWS Free plan balance at inspection: USD 97.12. FreeTierEligible is not a
guarantee that the usage costs nothing; resources consume applicable credits.

Mumbai Linux on-demand prices retrieved from AWS Pricing API:

| Option | Hourly compute/control plane | 30 days, 720 hours |
| --- | ---: | ---: |
| Two t2.medium nodes | $0.0992 | $71.424 |
| Two t3.small nodes | $0.0448 | $32.256 |
| EKS standard-support control plane | $0.10 | $72.00 |
| Proposed two t3.small + EKS | $0.1448 | $104.256 |
| Existing Jenkins m7i-flex.large compute | $0.10075 | $72.54 |

Storage, public IPv4, transfer, load balancers, and any applicable CPU surplus
charges are additional. Combined proposed EKS + existing Jenkins compute is
$0.24555/hour; $97.12 would cover less than 16.5 days of continuous use once
additional charges are included. Billing data may be delayed.

t2.medium is not FreeTierEligible according to the EC2 API. t3.small is marked
eligible but has only 2 GiB RAM per node, which limits application capacity.

Validate and deploy from an identity with
the required EKS, CloudFormation, EC2, IAM and related provisioning permissions:

```bash
eksctl create cluster --config-file cluster.proposed.yaml --dry-run
eksctl create cluster --config-file cluster.proposed.yaml
```

EKS control-plane charges continue even with zero workers. To end them, delete
the cluster after preserving any required workloads and persistent data.

## Access from this workstation

The local `kubeconfig` file is ignored by Git and uses AWS CLI authentication.
From the repository root, with the provisioning AWS identity configured:

```powershell
kubectl --kubeconfig devops_project/eks/kubeconfig get nodes -o wide
kubectl --kubeconfig devops_project/eks/kubeconfig get pods -A
```

The Jenkins instance role is separate from the provisioning identity. Jenkins
pipeline deployment access must be granted explicitly; ECR login does not grant
Kubernetes permissions.

When finished with the lab and after saving any required data, this command
deletes the cluster and its managed node group:

```powershell
eksctl delete cluster --name three-tier-k8s-eks-cluster --region ap-south-1 --wait
```

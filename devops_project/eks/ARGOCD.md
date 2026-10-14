# Argo CD on EKS

Cluster: three-tier-k8s-eks-cluster, region ap-south-1.
Pinned official release: v3.5.5. Apply with:

```powershell
kubectl --kubeconfig devops_project/eks/kubeconfig apply --server-side -k devops_project/eks/argocd
kubectl --kubeconfig devops_project/eks/kubeconfig get pods,svc -n argocd
```

## Access

https://k8s-argocd-argocdse-dfccfba3ad-3fb9a52d04726574.elb.ap-south-1.amazonaws.com

Username: admin. Retrieve the generated initial password locally:

```powershell
$encoded = kubectl --kubeconfig devops_project/eks/kubeconfig -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($encoded))
```

The server uses its default self-signed TLS certificate. A trusted certificate
and domain are needed to eliminate browser certificate warnings. Network access
is restricted to 38.254.174.214/32. Update the kustomization if your public IP changes.
This adds one billed AWS Network Load Balancer; no nodes were added or resized.

## Small-cluster configuration

The two t3.small nodes reached their pod limit during installation. Dex SSO,
ApplicationSet, and notifications deployments are scaled to zero. Core server,
repository server, Redis, and application controller remain enabled for normal
Git-based Applications and admin login. Resource requests/limits are patched
in kustomization.yaml. Capacity must be reassessed before deploying workloads.

## Application prerequisites

The three-tier namespace exists. Worker nodes already have the AWS managed
AmazonEC2ContainerRegistryPullOnly policy, so same-account ECR image pulls can
use node IAM without copying an expiring Docker login secret.

Both frontend and backend ECR repositories were empty at installation.
Application manifests also reference dovz.shop. Build and push images and
confirm the intended domain before syncing applications. No application was
synced and no GitHub credentials were copied. For a private repository, configure
read access in Argo CD Settings > Repositories using a read-only deploy key or token.
Never commit these credentials to Git.

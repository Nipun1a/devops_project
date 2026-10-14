# AWS Load Balancer Controller

Installed for `three-tier-k8s-eks-cluster` in `ap-south-1` (Mumbai), account
`598142778894`. Helm chart and controller version: `3.6.0` / `v3.6.0`.

The IAM provider is:
`oidc.eks.ap-south-1.amazonaws.com/id/82D1E90751CE1B9870CE589C98F9D91E`.
The dedicated IAM role is `AmazonEKSLoadBalancerControllerRole`, with attached
policy `AWSLoadBalancerControllerIAMPolicy`. Its trust is restricted to this
provider, audience `sts.amazonaws.com`, and service-account subject
`system:serviceaccount:kube-system:aws-load-balancer-controller`.

The policy is saved in `load-balancer-iam-policy.json`, downloaded from:
https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v3.6.0/docs/install/iam_policy.json

## Commands used

Run from the repository root in PowerShell. IAM policy creation is a one-time
operation; it fails if the policy already exists. These resources now exist.

```powershell
$env:KUBECONFIG = Join-Path (Get-Location) 'devops_project/eks/kubeconfig'
eksctl utils associate-iam-oidc-provider --region ap-south-1 --cluster three-tier-k8s-eks-cluster --approve

aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://devops_project/eks/load-balancer-iam-policy.json --output json

eksctl create iamserviceaccount --cluster three-tier-k8s-eks-cluster --namespace kube-system --name aws-load-balancer-controller --role-name AmazonEKSLoadBalancerControllerRole --attach-policy-arn arn:aws:iam::598142778894:policy/AWSLoadBalancerControllerIAMPolicy --approve --region ap-south-1

& ./devops_project/eks/tools/windows-amd64/helm.exe repo add eks https://aws.github.io/eks-charts
& ./devops_project/eks/tools/windows-amd64/helm.exe repo update eks
& ./devops_project/eks/tools/windows-amd64/helm.exe upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller --version 3.6.0 --namespace kube-system --kubeconfig devops_project/eks/kubeconfig --values devops_project/eks/load-balancer-values.yaml --wait --timeout 5m

kubectl --kubeconfig devops_project/eks/kubeconfig get deployment aws-load-balancer-controller -n kube-system
kubectl --kubeconfig devops_project/eks/kubeconfig get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

Helm v4.3.0 was downloaded from the official Helm distribution and SHA-256
verified. The local binary directory is ignored by Git. A standard installed
`helm` command can be used in place of this local executable.

The values file sets the region and VPC explicitly and reuses the eksctl-created
service account. Two controller replicas were verified Ready on separate nodes.

Installing the controller alone does not create an application load balancer.
An ALB is provisioned when a suitable application Ingress is deployed. No
application Ingress or test load balancer was created by this installation.

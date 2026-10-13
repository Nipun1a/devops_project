# Jenkins deployment

Deployed in `ap-south-1` with Terraform. Instance: `i-0b6a1a24d98b7b488`.
Jenkins: http://13.234.118.176:8080
SonarQube: http://13.234.118.176:9000

The existing IAM role, ECR policy, and instance profile are now managed in the
remote Terraform state. Do not apply the old `tfplan`; generate a fresh plan for
future changes. The DynamoDB backend deprecation warning is non-blocking; retain
the existing locking configuration until a coordinated S3 locking migration.

## Access and unlock

From this directory in PowerShell:

```powershell
ssh -i .\jenkins-access.pem ubuntu@13.234.118.176
```

On the instance, retrieve the setup password:

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Open Jenkins, enter this password, and complete the plugin/admin-account wizard.
The locally generated `jenkins-access.pem` is authorized on this instance and is
ignored by Git. Keep it private and backed up. The original `devsecops-project.pem`
is not a valid PEM key. Terraform still uses the existing AWS key-pair name
`devsecops-project`; the additional local access key is authorized only on this
instance and will need to be added again if the instance is replaced.

## Bootstrap and future changes

The m7i-flex.large has 8 GB RAM and runs Jenkins plus SonarQube. Jenkins uses a
512 MB Java heap, and the host has 2 GB swap. SonarQube is enabled by default.
SonarQube runs in the `sonar` container with PostgreSQL 17 in `sonar-db`. Both
restart automatically. Named Docker volumes persist database and analysis data.
Database credentials are stored only on the server under `/opt/sonarqube`.
The root disk is encrypted gp3, 30 GB. Startup installs Jenkins, Docker, AWS CLI,
kubectl, eksctl, Terraform, Trivy, and Helm.

```powershell
terraform validate
terraform plan -out="next.tfplan"
terraform apply "next.tfplan"
```

Changing user data does not rerun installation on an existing instance. The public
IP may change after stopping and starting the instance; use `terraform output`
after refreshing state to retrieve the updated address.

Verified after deployment: both EC2 health checks passed, cloud-init completed,
Jenkins and Docker were active, `/var/lib/jenkins-bootstrap-complete` existed,
and Jenkins 2.580.1 returned HTTP 200 on `/login`.

## SonarQube access

Initially sign in with username `admin` and password `admin`; SonarQube requires
a new password. In Jenkins's SonarQube server settings, use
`http://localhost:9000` because Jenkins and SonarQube run on this same host.
Generate a SonarQube token and save it as a Jenkins Secret text credential to
authenticate analysis. The scanner plugin alone does not install the server.

To install on an existing host, copy `scripts/install-sonarqube.sh` to the host
with Linux line endings and run it with `sudo bash`. Terraform user-data changes
alone do not rerun the startup script on an existing EC2 instance.

## AWS credits

On 13 October 2026, AWS reported an ACTIVE FREE account plan with $97.21 credits
remaining, expiring 16 February 2027 (or sooner if exhausted). AWS marks
m7i-flex.large as eligible for this plan. Its Mumbai Linux compute rate was
$0.10075/hour: $72.54 per 30 days of continuous operation, excluding storage,
public IPv4, and other services. Eligibility does not mean unlimited free usage.
Stop the instance when not studying to conserve compute credits; disk charges
continue while stopped. Stopping also makes both services unavailable, and the
public IP can change when restarted. This deployment did not upgrade the account
to a paid plan.

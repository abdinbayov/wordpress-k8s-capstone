# WordPress EKS Capstone - Setup Guide

Complete guide to deploy this WordPress application on AWS EKS using GitHub Actions CI/CD.

---

## 📋 Table of Contents

1. [Prerequisites]
2. [AWS Configuration]
3. [Remote State Backend Setup]
4. [GitHub Actions Setup]
5. [Deploy via GitHub Actions]
6. [Verification]
7. [Troubleshooting]

---

## Prerequisites

### ⚠️ Cost Warning

**This project will cost approximately $240-320/month on AWS:**

| Resource | Monthly Cost (est.) |
|----------|---------------------|
| EKS Cluster | $72 |
| 3× t3.medium EC2 nodes | $90 |
| 3× NAT Gateways | $100 |
| 2× Network Load Balancers | $45 |
| EBS volumes (40GB) | $4 |
| Data transfer | ~$10 |
| **Total** | **~$320/month** |

**💡 Important:**
- Use for short testing periods only
- Destroy immediately after testing (GitHub Actions workflow available)
- Consider using Spot instances for 70% savings

### Required Tools (for verification only)

You don't need these for deployment (GitHub Actions handles it), but useful for verification:
```bash
# macOS
brew install awscli kubectl

# Verify installations
aws --version
kubectl version --client
```

### AWS Account Requirements

- ✅ AWS account with admin access
- ✅ AWS credentials (Access Key ID + Secret Access Key)

---

## AWS Configuration

### Get AWS Credentials

1. Log in to AWS Console
2. Go to: **IAM** → **Users** → **Your User** → **Security credentials**
3. Click **"Create access key"**
4. Select: **"Command Line Interface (CLI)"**
5. Click **"Create access key"**
6. **Save both:**
   - Access key ID
   - Secret access key
   
⚠️ **Important:** Save these securely - you'll need them for GitHub Secrets!

---

## Remote State Backend Setup

This project uses **S3 + DynamoDB** for Terraform state management. You need to create these resources with **EXACT naming** for the backend configuration to work.

### Why These Exact Names?

The Terraform configuration already has the backend configured with these names:
- **S3 Bucket:** `wordpress-capstone-tfstate-TIMESTAMP`
- **DynamoDB Table:** `wordpress-capstone-terraform-locks`
- **Region:** `eu-north-1`

### Create S3 Bucket for State
```bash
# Set variables with EXACT naming pattern
AWS_REGION="eu-north-1"
STATE_BUCKET="wordpress-capstone-tfstate-$(date +%s)"
STATE_TABLE="wordpress-capstone-terraform-locks"

echo "=========================================="
echo "Creating Terraform state backend..."
echo "=========================================="
echo ""
echo "S3 Bucket: ${STATE_BUCKET}"
echo "DynamoDB Table: ${STATE_TABLE}"
echo "Region: ${AWS_REGION}"
echo ""

# Create S3 bucket
aws s3 mb s3://${STATE_BUCKET} --region ${AWS_REGION}

# Enable versioning (critical for state recovery)
aws s3api put-bucket-versioning \
  --bucket ${STATE_BUCKET} \
  --versioning-configuration Status=Enabled \
  --region ${AWS_REGION}

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket ${STATE_BUCKET} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }' \
  --region ${AWS_REGION}

# Block all public access (security!)
aws s3api put-public-access-block \
  --bucket ${STATE_BUCKET} \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
  --region ${AWS_REGION}

echo "✅ S3 bucket created: ${STATE_BUCKET}"
```

### Create DynamoDB Table for State Locking
```bash
# Create DynamoDB table with EXACT name
aws dynamodb create-table \
  --table-name ${STATE_TABLE} \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ${AWS_REGION}

echo "✅ DynamoDB table created: ${STATE_TABLE}"
```

### CRITICAL: Save Your Bucket Name
```bash
echo ""
echo "=========================================="
echo "⚠️  SAVE THIS BUCKET NAME!"
echo "=========================================="
echo ""
echo "Bucket: ${STATE_BUCKET}"
echo ""
echo "You'll need this in the next step!"
echo "=========================================="
```

### Update Terraform Backend Configuration

**Edit** `environments/dev/main.tf` and update the backend block:

Find this section:
```hcl
  backend "s3" {
    bucket         = "YOUR_BUCKET_NAME_HERE"  # ← Update this line
    key            = "wordpress-capstone/dev/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "wordpress-capstone-terraform-locks"
    encrypt        = true
  }
```

Replace `YOUR_BUCKET_NAME_HERE` with your actual bucket name from above!

**Example:**
```hcl
  backend "s3" {
    bucket         = "wordpress-capstone-tfstate-1731876543"  # ← Your bucket
    key            = "wordpress-capstone/dev/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "wordpress-capstone-terraform-locks"
    encrypt        = true
  }
```

### Commit the Change
```bash
git add environments/dev/main.tf
git commit -m "Update backend with my S3 bucket name"
git push origin main
```

---

## GitHub Actions Setup

### 1. Fork or Clone the Repository

**If you haven't already:**
```bash
git clone https://github.com/abdinbayov/wordpress-k8s-capstone.git
cd wordpress-k8s-capstone
```

### 2. Add GitHub Secrets

Go to your repository settings:

**URL Format:** `https://github.com/YOUR_USERNAME/wordpress-k8s-capstone/settings/secrets/actions`

Click **"New repository secret"** and add these **4 secrets**:

---

#### ① AWS_ACCESS_KEY_ID

- **Name:** `AWS_ACCESS_KEY_ID`
- **Value:** Your AWS access key ID (from AWS Console → IAM)
- Click **"Add secret"**

---

#### ② AWS_SECRET_ACCESS_KEY

- **Name:** `AWS_SECRET_ACCESS_KEY`
- **Value:** Your AWS secret access key (from AWS Console → IAM)
- Click **"Add secret"**

---

#### ③ MYSQL_PASSWORD

- **Name:** `MYSQL_PASSWORD`
- **Value:** `WordPress123!Secure` (or your custom password)
- **Note:** This is for the WordPress database user
- Click **"Add secret"**

---

#### ④ MYSQL_ROOT_PASSWORD

- **Name:** `MYSQL_ROOT_PASSWORD`
- **Value:** `RootPassword123!Secure` (or your custom password)
- **Note:** This is for the MySQL root user
- Click **"Add secret"**

---

### Verify Secrets Are Set

Your secrets page should look like this:
```
Repository secrets (4)
┌─────────────────────────────────────┐
│ AWS_ACCESS_KEY_ID           ••••••• │
│ AWS_SECRET_ACCESS_KEY       ••••••• │
│ MYSQL_PASSWORD              ••••••• │
│ MYSQL_ROOT_PASSWORD         ••••••• │
└─────────────────────────────────────┘
```

✅ All 4 secrets must be present!

---

## Deploy via GitHub Actions

### Option A: Automatic Deploy (Push to Main)

Any push to `main` branch triggers automatic deployment:
```bash
git add .
git commit -m "Deploy to AWS"
git push origin main
```

GitHub Actions will automatically:
1. Create VPC and networking
2. Deploy EKS cluster
3. Deploy WordPress and MySQL
4. Deploy Prometheus monitoring
5. Show URLs in the logs

---

### Option B: Manual Deploy

1. Go to your repository on GitHub
2. Click **"Actions"** tab
3. Select **"Deploy WordPress to EKS"** workflow
4. Click **"Run workflow"** (right side)
5. Select branch: `main`
6. Click **"Run workflow"** button

### Monitor Deployment Progress

- Click on the running workflow to see logs
- Deployment takes **20-25 minutes**
- ✅ Green checkmark = Success!
- ❌ Red X = Failed (check logs for errors)

### Get Your URLs

After deployment completes:

1. Go to the workflow run
2. Scroll to **"Get Service URLs"** step
3. Copy the URLs:
   - **WordPress:** `http://<load-balancer-url>`
   - **Prometheus:** `http://<load-balancer-url>:9090`

**Or check via CLI:**
```bash
# Configure kubectl
aws eks update-kubeconfig --region eu-north-1 --name wordpress-capstone-dev

# Get WordPress URL
kubectl get svc -n wordpress wordpress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Get Prometheus URL
kubectl get svc -n monitoring prometheus -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

---

## Destroy Infrastructure

**⚠️ CRITICAL:** Always destroy resources when done to avoid charges!

### Via GitHub Actions (Recommended)

1. Go to **Actions** tab
2. Select **"Destroy WordPress EKS Infrastructure"** workflow
3. Click **"Run workflow"**
4. Confirm by clicking **"Run workflow"**
5. Wait ~10-15 minutes for complete cleanup

### Verify Cleanup

After destroy completes, verify everything is deleted:
```bash
# Check EKS clusters
aws eks list-clusters --region eu-north-1

# Check NAT Gateways (these cost money!)
aws ec2 describe-nat-gateways --region eu-north-1 \
  --filter "Name=state,Values=available" \
  --query 'NatGateways[*].[NatGatewayId,State]'

# Check Load Balancers
aws elbv2 describe-load-balancers --region eu-north-1 \
  --query 'LoadBalancers[*].[LoadBalancerName,State.Code]'
```

All should return empty! ✅

---

## Verification

### Check Deployment Status
```bash
# Configure kubectl (if not done)
aws eks update-kubeconfig --region eu-north-1 --name wordpress-capstone-dev

# Check nodes (should show 3)
kubectl get nodes

# Check all pods
kubectl get pods --all-namespaces

# Check WordPress pods (should show 3 replicas)
kubectl get pods -n wordpress

# Check monitoring pods
kubectl get pods -n monitoring
```

### Expected Output
```bash
# Nodes
NAME                                          STATUS   ROLES    AGE
ip-10-0-1-xxx.eu-north-1.compute.internal    Ready    <none>   10m
ip-10-0-2-xxx.eu-north-1.compute.internal    Ready    <none>   10m
ip-10-0-3-xxx.eu-north-1.compute.internal    Ready    <none>   10m

# WordPress pods
NAME                              READY   STATUS    RESTARTS   AGE
mysql-xxxxx-xxxxx                1/1     Running   0          8m
mysql-exporter-xxxxx-xxxxx       1/1     Running   0          8m
wordpress-xxxxx-xxxxx            1/1     Running   0          8m
wordpress-xxxxx-xxxxx            1/1     Running   0          8m
wordpress-xxxxx-xxxxx            1/1     Running   0          8m

# Monitoring pods
NAME                          READY   STATUS    RESTARTS   AGE
prometheus-xxxxx-xxxxx       1/1     Running   0          8m
```

### Check Prometheus Metrics

1. Open Prometheus: `http://<PROMETHEUS-URL>:9090`
2. Go to: **Status** → **Targets**
3. Verify all targets are **UP** (green):
   - `kubernetes-apiservers` (2/2 up)
   - `kubernetes-nodes` (3/3 up)
   - `kubernetes-pods` (all up including mysql-exporter)

### Test Queries

In Prometheus, run these queries:
```promql
# Check MySQL is running
mysql_up
# Should return: 1

# MySQL queries per second
rate(mysql_global_status_queries[1m])

# Node CPU usage
node_cpu_seconds_total

# WordPress pod health
up{namespace="wordpress"}
# Should return: 1 for each pod
```

---

## Troubleshooting

### Issue: GitHub Actions - "Backend Configuration Changed"

**Error:** `Error: Backend configuration changed`

**Solution:**

Make sure you updated `environments/dev/main.tf` with YOUR bucket name!
```hcl
backend "s3" {
  bucket = "wordpress-capstone-tfstate-YOUR-TIMESTAMP"  # ← Check this!
}
```

---

### Issue: GitHub Actions - Authentication Failed

**Error:** `Unable to locate credentials`

**Solution:**

1. Go to: **Settings** → **Secrets** → **Actions**
2. Verify all 4 secrets are present:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `MYSQL_PASSWORD`
   - `MYSQL_ROOT_PASSWORD`
3. If missing, add them again

---

### Issue: GitHub Actions - S3 Bucket Not Found

**Error:** `NoSuchBucket: The specified bucket does not exist`

**Solutions:**

1. **Check bucket exists:**
```bash
   aws s3 ls | grep wordpress-capstone-tfstate
```

2. **If bucket doesn't exist, create it:**
```bash
   # Follow steps in "Remote State Backend Setup" section
```

3. **Verify bucket name in main.tf matches actual bucket:**
```bash
   # Compare:
   grep bucket environments/dev/main.tf
   aws s3 ls | grep wordpress-capstone-tfstate
```

---

### Issue: Pods Stuck in Pending

**Error:** Pods show "Pending" status for a long time

**Solution:**

EBS CSI driver issue. The workflow should handle this, but if not:
```bash
# Check EBS CSI driver
kubectl get pods -n kube-system | grep ebs-csi

# If not running, the workflow will retry
# Or manually apply:
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.25"
```

---

### Issue: LoadBalancer URL Not Working

**Problem:** Can't access WordPress or Prometheus

**Solutions:**

1. **Wait longer:** LoadBalancers take 2-3 minutes to provision

2. **Check LoadBalancer status:**
```bash
   kubectl get svc -n wordpress wordpress
   kubectl get svc -n monitoring prometheus
   
   # If showing <pending>, wait a few more minutes
```

3. **Check AWS Console:**
   - Go to: **EC2** → **Load Balancers**
   - Look for LoadBalancers with your cluster name
   - Check if they're "active"

---

### Issue: High AWS Costs

**Problem:** Unexpected charges

**Solution:**
```bash
# Destroy IMMEDIATELY
# Go to GitHub Actions → "Destroy..." workflow → Run workflow

# Verify everything deleted:
aws eks list-clusters --region eu-north-1
aws ec2 describe-nat-gateways --region eu-north-1 --filter "Name=state,Values=available"
aws elbv2 describe-load-balancers --region eu-north-1

# Check billing:
# Go to: AWS Console → Billing Dashboard
```

---

### Issue: Prometheus Shows 403 Errors

**Error:** Node metrics showing "Forbidden"

**Solution:**

This is already fixed in the configuration! Prometheus uses API proxy for node metrics.

If still seeing issues:
```bash
# Restart Prometheus
kubectl delete pod -n monitoring -l app=prometheus
```

---

## Architecture Overview
```
Internet
   ↓
Network Load Balancer (Public)
   ↓
┌─────────────────────────────────────────────┐
│         Kubernetes Cluster (EKS)            │
│                                             │
│  ┌──────────────┐      ┌────────────────┐  │
│  │  WordPress   │─────→│     MySQL      │  │
│  │  (3 replicas)│      │  (Persistent)  │  │
│  └──────────────┘      └────────┬───────┘  │
│         ↓                       │          │
│  ┌──────────────┐      ┌────────▼───────┐  │
│  │  Prometheus  │←─────│  MySQL Exporter│  │
│  │  (Monitoring)│      └────────────────┘  │
│  └──────────────┘                          │
│                                             │
│  Infrastructure:                            │
│  • 3 Nodes (t3.medium) across 3 AZs        │
│  • Private subnets for security            │
│  • NAT Gateways for outbound traffic       │
│  • EBS volumes for persistence             │
└─────────────────────────────────────────────┘
```

**Learn more:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

---

## What Gets Deployed

### Infrastructure Layer
- ✅ VPC (10.0.0.0/16)
- ✅ 3 Public subnets (for LoadBalancers, NAT Gateways)
- ✅ 3 Private subnets (for EKS nodes)
- ✅ 3 NAT Gateways (one per AZ)
- ✅ Internet Gateway
- ✅ Security Groups
- ✅ IAM Roles and Policies

### Compute Layer
- ✅ EKS Cluster (Kubernetes 1.28)
- ✅ 3 Worker Nodes (t3.medium)
- ✅ Auto-scaling (2-5 nodes)

### Application Layer
- ✅ WordPress (3 replicas with anti-affinity)
- ✅ MySQL (1 replica with 20GB EBS volume)
- ✅ 2 LoadBalancers (WordPress + Prometheus)

### Monitoring Layer
- ✅ Prometheus server
- ✅ MySQL exporter
- ✅ Node metrics via Kubernetes API
- ✅ Pod metrics with service discovery

---

## Additional Documentation

- **[README.md](README.md)** - Project overview
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Detailed architecture
- **[docs/METRICS.md](docs/METRICS.md)** - Monitoring guide  
- **[docs/SECURITY.md](docs/SECURITY.md)** - Security best practices
- **[docs/FAULT_TOLERANCE_TESTS.md](docs/FAULT_TOLERANCE_TESTS.md)** - Test results

---

## Cost Optimization

### Use Spot Instances (Save 70%)

Edit `modules/eks-cluster/main.tf`:
```hcl
capacity_type = "SPOT"  # Instead of "ON_DEMAND"
```

### Use Smaller Instances

Edit `environments/dev/terraform.tfvars`:
```hcl
node_instance_types = ["t3.small"]  # Instead of t3.medium
```

### Reduce Node Count

Edit `environments/dev/terraform.tfvars`:
```hcl
node_desired_size = 2  # Instead of 3
```

---

## Support

Need help?

1. Check [Troubleshooting](#troubleshooting) section
2. Review GitHub Actions logs
3. Check pod logs: `kubectl logs -n wordpress <pod-name>`
4. Open an issue on GitHub

---

## Important Reminders

✅ **Always** update backend configuration with YOUR bucket name  
✅ **Always** set all 4 GitHub Secrets  
✅ **Always** destroy resources after testing (to avoid charges)  
✅ **Monitor** AWS billing dashboard regularly  
✅ **Verify** cleanup completed (no resources left)  

---

**🎉 You're ready to deploy! Follow the steps above and you'll have a production-grade WordPress deployment on AWS EKS!**

**Cost reminder:** Run destroy workflow when done! 💰

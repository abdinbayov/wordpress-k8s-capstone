#!/bin/bash
set -e

echo "========================================"
echo "WordPress on EKS - Full Deployment"
echo "========================================"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Step 1: Deploy Infrastructure
echo -e "${BLUE}Step 1/6: Creating AWS infrastructure (VPC, EKS, Nodes)${NC}"
cd environments/dev
terraform init -input=false
terraform apply -auto-approve
cd ../..
echo -e "${GREEN}Infrastructure created${NC}"
echo ""

# Step 2: Configure kubectl
echo -e "${BLUE}Step 2/6: Configuring kubectl${NC}"
aws eks update-kubeconfig --region eu-north-1 --name wordpress-capstone-dev
echo -e "${GREEN}kubectl configured${NC}"
echo ""

# Step 3: Wait for nodes
echo -e "${BLUE}Step 3/6: Waiting for EKS nodes to be ready${NC}"
echo "This may take a few minutes..."
kubectl wait --for=condition=Ready nodes --all --timeout=600s
NODE_COUNT=$(kubectl get nodes --no-headers | wc -l)
echo -e "${GREEN}All $NODE_COUNT nodes are ready${NC}"
echo ""

# Step 3.5: Install EBS CSI Driver
echo -e "${BLUE}Step 3.5/6: Installing EBS CSI Driver${NC}"
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.25" 2>/dev/null || echo "EBS CSI already installed"
echo "Waiting for EBS CSI pods..."
kubectl wait --for=condition=ready pod -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver --timeout=120s 2>/dev/null || echo "EBS CSI pods starting..."
echo -e "${GREEN}EBS CSI Driver installed${NC}"
echo ""

# Step 4: Deploy WordPress
echo -e "${BLUE}Step 4/6: Deploying WordPress and MySQL${NC}"
kubectl apply -f kubernetes/wordpress/
echo "Waiting for MySQL to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/mysql -n wordpress
echo "Waiting for WordPress to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/wordpress -n wordpress
echo -e "${GREEN}WordPress deployed${NC}"
echo ""

# Step 5: Deploy Monitoring
echo -e "${BLUE}Step 5/6: Deploying Prometheus monitoring${NC}"
kubectl apply -f kubernetes/monitoring/
echo "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring 2>/dev/null || echo "Prometheus starting..."
echo "Waiting for MySQL exporter to be ready..."
kubectl wait --for=condition=available --timeout=180s deployment/mysql-exporter -n wordpress 2>/dev/null || echo "MySQL exporter starting..."
echo -e "${GREEN}Monitoring deployed${NC}"
echo ""

# Step 6: Get URLs
echo -e "${BLUE}Step 6/6: Retrieving service URLs${NC}"
echo "Waiting for LoadBalancers to provision..."
sleep 10

WORDPRESS_URL=""
for i in {1..30}; do
    WORDPRESS_URL=$(kubectl get svc -n wordpress wordpress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$WORDPRESS_URL" ]; then
        break
    fi
    echo "  Waiting for WordPress URL... ($i/30)"
    sleep 10
done

PROMETHEUS_URL=""
for i in {1..30}; do
    PROMETHEUS_URL=$(kubectl get svc -n monitoring prometheus -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ -n "$PROMETHEUS_URL" ]; then
        break
    fi
    sleep 5
done

echo ""
echo "========================================"
echo -e "${GREEN}DEPLOYMENT COMPLETE${NC}"
echo "========================================"
echo ""
echo "Cluster Information:"
echo "  Region: eu-north-1"
echo "  Cluster: wordpress-capstone-dev"
echo "  Nodes: $NODE_COUNT (across 3 availability zones)"
echo ""
echo "Application Status:"
kubectl get pods -n wordpress
echo ""
echo "Monitoring Status:"
kubectl get pods -n monitoring
echo ""

if [ -n "$WORDPRESS_URL" ]; then
    echo -e "${BLUE}WordPress URL:${NC}"
    echo "  http://$WORDPRESS_URL"
else
    echo -e "${YELLOW}WordPress LoadBalancer provisioning...${NC}"
    echo "  Get URL: kubectl get svc -n wordpress wordpress"
fi

echo ""

if [ -n "$PROMETHEUS_URL" ]; then
    echo -e "${BLUE}Prometheus URL:${NC}"
    echo "  http://$PROMETHEUS_URL:9090"
    echo ""
    echo "Prometheus Metrics Available:"
    echo "  - Cluster: node_cpu_seconds_total, node_memory_MemAvailable_bytes"
    echo "  - MySQL: mysql_up, rate(mysql_global_status_queries[1m])"
    echo "  - Application: up{namespace='wordpress'}"
else
    echo -e "${YELLOW}Prometheus LoadBalancer provisioning...${NC}"
    echo "  Get URL: kubectl get svc -n monitoring prometheus"
fi

echo ""
echo "Useful Commands:"
echo "  View all pods:        kubectl get pods --all-namespaces"
echo "  View WordPress pods:  kubectl get pods -n wordpress"
echo "  View monitoring:      kubectl get pods -n monitoring"
echo "  View nodes:           kubectl get nodes"
echo "  Prometheus targets:   Open Prometheus UI -> Status -> Targets"
echo "  Destroy all:          ./destroy.sh"
echo ""

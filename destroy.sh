#!/bin/bash
set -e

echo "========================================"
echo "Destroying WordPress EKS Infrastructure"
echo "========================================"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Step 1/3: Deleting Kubernetes resources${NC}"
kubectl delete namespace wordpress --ignore-not-found=true --timeout=120s 2>/dev/null || echo "WordPress namespace not found"
kubectl delete namespace monitoring --ignore-not-found=true --timeout=120s 2>/dev/null || echo "Monitoring namespace not found"

echo -e "${YELLOW}Waiting for LoadBalancers to be deleted (2 minutes)...${NC}"
sleep 120
echo -e "${GREEN}Kubernetes resources deleted${NC}"
echo ""

echo -e "${BLUE}Step 2/3: Verifying LoadBalancers are gone${NC}"
LB_COUNT=$(aws elbv2 describe-load-balancers --region eu-north-1 --query 'length(LoadBalancers)' --output text 2>/dev/null || echo "0")
if [ "$LB_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}Warning: $LB_COUNT LoadBalancer(s) still exist. Waiting 60 more seconds...${NC}"
    sleep 60
fi
echo -e "${GREEN}LoadBalancers cleared${NC}"
echo ""

echo -e "${BLUE}Step 3/3: Destroying infrastructure with Terraform${NC}"
cd environments/dev
terraform destroy -auto-approve
cd ../..
echo -e "${GREEN}Infrastructure destroyed${NC}"
echo ""

echo "========================================"
echo -e "${GREEN}CLEANUP COMPLETE${NC}"
echo "========================================"
echo ""

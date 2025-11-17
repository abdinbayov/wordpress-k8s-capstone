# Security Best Practices

## Secrets Management

### Production Setup

This project uses **placeholder values** in Kubernetes manifests that are replaced at deploy time with actual secrets from:

- **CI/CD:** GitHub Actions Secrets
- **Local:** Environment variables or prompted input

### Why Not Store Passwords in Git?

❌ **Never commit:**
- Database passwords
- API keys
- Private keys
- Certificates

✅ **Instead use:**
- GitHub Secrets (for CI/CD)
- AWS Secrets Manager (for production)
- Environment variables (for local dev)

### GitHub Secrets Required

For CI/CD to work, set these in GitHub repository secrets:

1. `AWS_ACCESS_KEY_ID` - AWS credentials
2. `AWS_SECRET_ACCESS_KEY` - AWS credentials  
3. `MYSQL_PASSWORD` - WordPress database password
4. `MYSQL_ROOT_PASSWORD` - MySQL root password

### Local Development
```bash
# Option 1: Set environment variables
export MYSQL_PASSWORD="your_password"
export MYSQL_ROOT_PASSWORD="your_root_password"
./deploy.sh

# Option 2: Let deploy.sh prompt you
./deploy.sh
# Script will ask for passwords interactively
```

### Production Recommendations

For production deployments, implement:

1. **AWS Secrets Manager** + **External Secrets Operator**
   - Centralized secret management
   - Automatic rotation
   - Audit logging

2. **Sealed Secrets**
   - Encrypt secrets in Git
   - Decrypt in-cluster

3. **HashiCorp Vault**
   - Dynamic secrets
   - Fine-grained access control

### Current Security Measures

✅ Passwords injected at deploy time (not in Git)
✅ Kubernetes Secrets base64 encoded
✅ Terraform state in encrypted S3 bucket
✅ Private subnets for workloads
✅ Security groups restrict traffic
✅ IAM roles with least privilege

### Future Improvements

- [ ] Rotate database passwords regularly
- [ ] Implement AWS Secrets Manager
- [ ] Add network policies
- [ ] Enable pod security policies
- [ ] Implement HTTPS with cert-manager
- [ ] Add WAF for LoadBalancer

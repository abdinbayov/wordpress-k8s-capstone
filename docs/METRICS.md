# Monitoring and Metrics Guide

## Overview

This deployment includes comprehensive monitoring using Prometheus to collect metrics from:
- Kubernetes cluster (nodes, API server)
- MySQL database
- Application pods

## Accessing Prometheus

Get Prometheus URL:
```bash
kubectl get svc -n monitoring prometheus
```

Open: `http://<EXTERNAL-IP>:9090`

## Available Metrics

### 1. Cluster Metrics

**Node CPU Usage:**
```promql
rate(node_cpu_seconds_total{mode!="idle"}[5m])
```

**Node Memory Available:**
```promql
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100
```

**Node Count:**
```promql
count(kube_node_info)
```

### 2. Application Health

**Pod Status:**
```promql
up{namespace="wordpress"}
```

**Pod Restarts (Health Indicator):**
```promql
rate(kube_pod_container_status_restarts_total{namespace="wordpress"}[5m])
```

**WordPress Pod Count:**
```promql
count(kube_pod_info{namespace="wordpress", pod=~"wordpress.*"})
```

### 3. MySQL Metrics

**MySQL Status:**
```promql
mysql_up
```

**Queries Per Second:**
```promql
rate(mysql_global_status_queries[1m])
```

**Active Connections:**
```promql
mysql_global_status_threads_connected
```

**Database Uptime:**
```promql
mysql_global_status_uptime
```

## Monitoring Architecture
```
Prometheus (monitoring namespace)
  ↓
Scrapes metrics every 15s from:
  ├── Kubernetes API Server (cluster health)
  ├── Kubernetes Nodes (via API proxy)
  │   └── Metrics: CPU, memory, disk, network
  ├── MySQL Exporter (wordpress namespace)
  │   └── Metrics: queries/sec, connections, uptime
  └── WordPress Pods
      └── Metrics: pod health, restarts
```

## Verifying Metrics Collection

1. **Check Prometheus Targets:**
   - Open Prometheus UI
   - Navigate to: Status → Targets
   - Verify all targets show "UP"

2. **Expected Targets:**
   - `kubernetes-apiservers`: 2/2 up
   - `kubernetes-nodes`: 3/3 up
   - `kubernetes-pods`: All up (including mysql-exporter)

## Troubleshooting

**If metrics are missing:**
```bash
# Check Prometheus is running
kubectl get pods -n monitoring

# Check Prometheus logs
kubectl logs -n monitoring -l app=prometheus

# Check MySQL exporter
kubectl get pods -n wordpress -l app=mysql-exporter
kubectl logs -n wordpress -l app=mysql-exporter

# Restart Prometheus if needed
kubectl delete pod -n monitoring -l app=prometheus
```

## Metrics Requirements Met

✅ **Cluster metrics:** Node CPU, memory, network, disk  
✅ **Application health:** Pod status, restarts, availability  
✅ **Database metrics:** MySQL queries/sec, connections, health  
✅ **Access patterns:** Pod metrics show request handling  

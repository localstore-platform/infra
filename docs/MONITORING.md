# Monitoring Setup

This document covers monitoring configuration for the LocalStore Platform.

## Monitoring Stack

For MVP, we use AWS CloudWatch for simplicity and cost-effectiveness.

```
┌─────────────────────────────────────────────┐
│              Monitoring Stack               │
├─────────────────────────────────────────────┤
│  CloudWatch Metrics    (Infrastructure)     │
│  CloudWatch Logs       (Application)        │
│  CloudWatch Alarms     (Alerting)           │
│  CloudWatch Dashboard  (Visualization)      │
└─────────────────────────────────────────────┘
```

## Key Metrics

### Infrastructure Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| CPU Utilization | <60% | >80% for 5 min |
| Memory Usage | <70% | >85% for 5 min |
| Disk Usage | <80% | >90% |
| Network In/Out | Baseline | 2x baseline |

### Application Metrics

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| API Response Time | <500ms p95 | >2s p95 |
| Error Rate | <1% | >5% |
| Request Rate | Baseline | 3x baseline (DDoS) |
| Database Connections | <80% | >90% |

### Business Metrics

| Metric | Description |
|--------|-------------|
| Active Sessions | Concurrent QR sessions |
| Orders/Hour | Order throughput |
| Payment Success Rate | Payment completion % |

## CloudWatch Configuration

### Install CloudWatch Agent

On EC2 instance:

```bash
# Install agent
sudo yum install amazon-cloudwatch-agent -y

# Configure agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard

# Start agent
sudo systemctl start amazon-cloudwatch-agent
sudo systemctl enable amazon-cloudwatch-agent
```

### CloudWatch Agent Config

```json
{
  "metrics": {
    "metrics_collected": {
      "mem": {
        "measurement": ["mem_used_percent"]
      },
      "disk": {
        "measurement": ["used_percent"],
        "resources": ["/"]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/opt/localstore/logs/*.log",
            "log_group_name": "localstore-prod-app",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
```

## Alarms

### CPU High Alarm

```hcl
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "localstore-prod-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization > 80% for 10 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    InstanceId = aws_instance.app.id
  }
}
```

### Memory High Alarm

```hcl
resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "localstore-prod-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Memory usage > 85% for 10 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

### API Error Rate Alarm

```hcl
resource "aws_cloudwatch_metric_alarm" "api_errors" {
  alarm_name          = "localstore-prod-api-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5XXError"
  namespace           = "LocalStore/API"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = ">10 5XX errors in 10 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
```

## Dashboards

### Main Dashboard Widgets

1. **EC2 Overview**
   - CPU Utilization
   - Memory Usage
   - Disk Usage
   - Network I/O

2. **Application Health**
   - Request count
   - Error rate
   - Response time (p50, p95, p99)

3. **Database**
   - Connection count
   - Query duration
   - Slow queries

4. **Redis**
   - Memory usage
   - Hit rate
   - Connection count

## Log Aggregation

### Application Logs

Docker logs are forwarded to CloudWatch:

```yaml
# docker-compose.prod.yml
services:
  api:
    logging:
      driver: awslogs
      options:
        awslogs-region: ap-southeast-1
        awslogs-group: localstore-prod-api
        awslogs-stream-prefix: api
```

### Log Insights Queries

**Error Analysis:**
```
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100
```

**Slow API Requests:**
```
fields @timestamp, path, duration
| filter duration > 1000
| sort duration desc
| limit 50
```

**Request Volume by Endpoint:**
```
fields path
| stats count(*) as requests by path
| sort requests desc
| limit 20
```

## Alerting

### SNS Topic Setup

```hcl
resource "aws_sns_topic" "alerts" {
  name = "localstore-prod-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "ops@localstore.ai"
}
```

### Alert Escalation

| Severity | Response Time | Channel |
|----------|---------------|---------|
| Critical | 15 min | SMS + Phone |
| High | 1 hour | Email + Slack |
| Medium | 4 hours | Email |
| Low | 24 hours | Dashboard |

## Health Checks

### API Health Endpoint

```bash
# Check API health
curl https://YOUR_DOMAIN/health

# Expected response
{
  "status": "ok",
  "timestamp": "2025-01-01T00:00:00Z",
  "services": {
    "database": "connected",
    "redis": "connected"
  }
}
```

### Synthetic Monitoring

Use CloudWatch Synthetics for uptime monitoring:

```hcl
resource "aws_synthetics_canary" "api_health" {
  name                 = "localstore-api-health"
  artifact_s3_location = "s3://localstore-canaries/"
  execution_role_arn   = aws_iam_role.canary.arn
  handler              = "apiCanaryBlueprint.handler"
  runtime_version      = "syn-python-selenium-2.0"
  
  schedule {
    expression = "rate(5 minutes)"
  }
}
```

## Runbook Integration

### Common Issues

| Alert | Likely Cause | Action |
|-------|-------------|--------|
| CPU High | Traffic spike | Scale up or investigate |
| Memory High | Memory leak | Restart service |
| Disk Full | Logs not rotated | Clean logs, add rotation |
| API Errors | Code bug | Check logs, rollback |
| DB Connections | Connection leak | Restart API, fix leak |

### Quick Commands

```bash
# Check system resources
htop
df -h
free -m

# Check Docker containers
docker compose ps
docker stats

# View recent logs
docker compose logs --tail=100

# Restart problematic service
docker compose restart api
```

## Cost Optimization

CloudWatch costs (estimated):
- Metrics: $0.30/metric/month
- Logs: $0.50/GB ingested + $0.03/GB stored
- Alarms: $0.10/alarm/month
- Dashboards: $3/dashboard/month

**Tips:**
- Use log retention policies (30 days for most)
- Filter logs before ingestion
- Use metric math instead of custom metrics
- Consolidate dashboards

## Related Documents

- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment guide
- [SECURITY.md](SECURITY.md) - Security configuration
- [../SPEC_LINKS.md](../SPEC_LINKS.md) - Specification references

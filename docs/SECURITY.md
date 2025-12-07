# Security Configuration

This document outlines security configurations for the LocalStore Platform infrastructure.

## Security Architecture

```plaintext
┌─────────────────────────────────────────────────────────────┐
│                     Security Layers                         │
├─────────────────────────────────────────────────────────────┤
│  CloudFlare (DDoS protection, WAF)                          │
├─────────────────────────────────────────────────────────────┤
│  AWS Security Groups (Network firewall)                     │
├─────────────────────────────────────────────────────────────┤
│  Nginx (Rate limiting, SSL termination)                     │
├─────────────────────────────────────────────────────────────┤
│  Application (JWT auth, input validation)                   │
├─────────────────────────────────────────────────────────────┤
│  Database (RLS policies, encrypted connections)             │
└─────────────────────────────────────────────────────────────┘
```

## Security Groups

### API Security Group

| Type | Port | Source | Description |
|------|------|--------|-------------|
| Inbound | 22 | Admin IP | SSH access |
| Inbound | 80 | 0.0.0.0/0 | HTTP (redirect to HTTPS) |
| Inbound | 443 | 0.0.0.0/0 | HTTPS |
| Outbound | All | 0.0.0.0/0 | All outbound |

### Database Security Group

| Type | Port | Source | Description |
|------|------|--------|-------------|
| Inbound | 5432 | API SG | PostgreSQL from API |
| Inbound | 6379 | API SG | Redis from API |
| Outbound | None | - | No outbound access |

## Secrets Management

### AWS Secrets Manager (Recommended)

Store sensitive values in AWS Secrets Manager:

```bash
# Create secret
aws secretsmanager create-secret \
    --name localstore/prod/database \
    --secret-string '{"username":"localstore","password":"SECURE_PASSWORD"}'

# Retrieve in application
aws secretsmanager get-secret-value --secret-id localstore/prod/database
```

### Environment Variables

For MVP, use environment variables with encrypted EBS:

```bash
# .env file on EC2 (never commit to git)
DB_PASSWORD=secure_password_here
JWT_SECRET=64_char_random_string_here
REDIS_PASSWORD=another_secure_password
```

## SSL/TLS Configuration

### CloudFlare Proxy Mode

SSL is handled automatically by CloudFlare proxy (orange cloud icon):

- Free SSL/TLS certificates (auto-provisioned)
- DDoS protection
- WAF (Web Application Firewall)
- Hidden origin IP

Set CloudFlare SSL mode to "Flexible" in the dashboard.

### Nginx Configuration

See [docker/nginx/conf.d/api.conf](../docker/nginx/conf.d/api.conf) for:

- CloudFlare IP allowlisting
- Real IP extraction from CF-Connecting-IP header
- Rate limiting

## Network Security

### VPC Configuration

- Single VPC for all resources
- Public subnet for EC2 (with Internet Gateway)
- Private subnet for databases (future)
- VPC Flow Logs enabled

### Rate Limiting

Nginx configuration (60 requests/minute):

```nginx
limit_req_zone $binary_remote_addr zone=api:10m rate=60r/m;

location /api/ {
    limit_req zone=api burst=20 nodelay;
}
```

## Application Security

### Authentication

- OTP-based authentication (no passwords stored)
- JWT tokens with 24-hour expiry
- Refresh tokens with 30-day expiry
- Token rotation on refresh

### Row-Level Security (RLS)

PostgreSQL RLS ensures tenant isolation:

```sql
-- Set current tenant before queries
SELECT set_current_tenant('tenant-uuid');

-- RLS policy enforces tenant_id matching
CREATE POLICY tenant_isolation ON orders
    USING (tenant_id = get_current_tenant());
```

### Input Validation

- All inputs validated at API layer
- Parameterized queries (TypeORM)
- XSS protection via response headers
- CORS restricted to allowed origins

## Security Monitoring

### CloudWatch Alerts

Configure alerts for:

- Failed SSH login attempts
- Unusual API error rates (>5%)
- High network traffic spikes
- Unauthorized API access attempts

### Logging

All logs retained for:

- VPC Flow Logs: 30 days
- Application logs: 90 days
- Audit logs: 1 year

## Security Checklist

### Before Deployment

- [ ] Change all default passwords
- [ ] Generate new JWT secret (64+ characters)
- [ ] Restrict SSH to specific IPs
- [ ] Enable EBS encryption
- [ ] Configure security groups
- [ ] Set up SSL certificates

### After Deployment

- [ ] Verify SSL certificate valid
- [ ] Test rate limiting works
- [ ] Confirm RLS policies active
- [ ] Check VPC Flow Logs enabled
- [ ] Review CloudWatch alerts

### Regular Maintenance

- [ ] Rotate secrets quarterly
- [ ] Review security group rules monthly
- [ ] Audit user access monthly
- [ ] Apply security patches weekly
- [ ] Renew SSL certificates (auto)

## Incident Response

### Security Incident Procedure

1. **Detect**: CloudWatch alert or manual detection
2. **Contain**: Revoke compromised credentials immediately
3. **Investigate**: Review logs for scope of breach
4. **Remediate**: Patch vulnerability, rotate all secrets
5. **Recover**: Restore from backup if needed
6. **Document**: Post-incident report

### Emergency Contacts

- Security Lead: [security@localstore.ai]
- AWS Support: Via AWS Console
- CloudFlare: Via Dashboard

## Compliance Notes

### Vietnam Market

- No specific data residency requirements for MVP
- VNPay/MoMo integration requires secure webhooks
- Customer data encrypted at rest and in transit

### PCI DSS Considerations

- No credit card data stored
- Payment processing via VNPay/MoMo (PCI compliant)
- Webhook payloads logged without sensitive data

## Related Documents

- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment guide
- [MONITORING.md](MONITORING.md) - Monitoring setup
- [../SPEC_LINKS.md](../SPEC_LINKS.md) - Specification references

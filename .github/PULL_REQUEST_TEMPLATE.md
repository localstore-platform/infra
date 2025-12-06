## Summary

<!-- Short description of infrastructure change (resources affected, cloud provider) -->

## Related Issue / Ticket

<!-- Link to issue, ticket, or spec reference -->
- Issue: #
- Spec: [SPEC_LINKS.md section](../SPEC_LINKS.md)

## Type of Change

- [ ] Terraform change
- [ ] Docker configuration
- [ ] CI/CD workflow
- [ ] Kubernetes manifests
- [ ] Scripts/automation
- [ ] Documentation

## Resources Affected

| Resource | Action | Environment |
|----------|--------|-------------|
| | create/update/destroy | dev/staging/prod |

## Plan & State

<!-- Attach or link to `terraform plan` output -->

<details>
<summary>Terraform Plan Output</summary>

```hcl
# Paste terraform plan output here
```

</details>

## Risk & Rollback

- **Downtime Required:** Yes / No
- **Data Migration:** Yes / No
- **Rollback Steps:**
  1. 

## Security & Cost

- [ ] No new IAM permissions required
- [ ] No new public endpoints exposed
- [ ] No secrets committed to repository
- **Estimated Cost Impact:** $X/month

## Testing

- [ ] Tested in development environment
- [ ] Terraform plan reviewed
- [ ] Docker containers verified locally

## Checklist

- [ ] `terraform fmt` passed
- [ ] `terraform validate` passed
- [ ] `terraform plan` attached and reviewed
- [ ] State locking verified
- [ ] No secrets in code (use Secrets Manager)
- [ ] Tags applied to all AWS resources
- [ ] Documentation updated if needed
- [ ] Monitoring/alerting updated if applicable

## Screenshots / Logs

<!-- Add any relevant screenshots or log outputs -->

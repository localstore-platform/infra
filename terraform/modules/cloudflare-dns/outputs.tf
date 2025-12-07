# CloudFlare DNS Module - Outputs

output "api_hostname" {
  description = "Full hostname for the API"
  value       = cloudflare_dns_record.api.name
}

output "api_record_id" {
  description = "CloudFlare record ID"
  value       = cloudflare_dns_record.api.id
}

output "zone_id" {
  description = "CloudFlare zone ID"
  value       = data.cloudflare_zone.main.zone_id
}

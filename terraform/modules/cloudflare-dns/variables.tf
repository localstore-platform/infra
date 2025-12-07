# CloudFlare DNS Module - Variables

variable "domain" {
  description = "Root domain name (e.g., localstore-platform.com)"
  type        = string
  default     = "localstore-platform.com"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "origin_ip" {
  description = "Origin server IP address (EC2 public IP)"
  type        = string
}

variable "proxied" {
  description = "Whether to proxy through CloudFlare (enables SSL, DDoS, CDN)"
  type        = bool
  default     = true
}

variable "create_healthcheck" {
  description = "Whether to create a CloudFlare health check"
  type        = bool
  default     = false  # Health checks require paid plan
}

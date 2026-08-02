variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Local AWS shared-config profile to run tofu as. Leave empty to use the default credential chain (env vars, SSO, or an assumed role in CI)."
  type        = string
  default     = ""
}

variable "project" {
  description = "Short project name; used as a prefix for every resource."
  type        = string
  default     = "django-container"
}

variable "environment" {
  description = "Deployment environment name (production, staging, ...)."
  type        = string
  default     = "production"
}

# ---------------------------------------------------------------- networking

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 4
    error_message = "az_count must be between 2 and 4 (an ALB requires at least two)."
  }
}

# ---------------------------------------------------------------------- app

variable "container_port" {
  description = "Port gunicorn listens on inside the container."
  type        = number
  default     = 8000
}

variable "image_tag" {
  description = "ECR image tag deployed by `tofu apply`. CI updates the service out-of-band afterwards."
  type        = string
  default     = "latest"
}

variable "task_cpu" {
  description = "Fargate task CPU units (1024 = 1 vCPU)."
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory in MiB. Must be valid for the chosen CPU."
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Baseline number of running tasks."
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Autoscaling floor."
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Autoscaling ceiling."
  type        = number
  default     = 4
}

variable "health_check_path" {
  description = "Path the ALB health-checks. Handled by HealthCheckMiddleware."
  type        = string
  default     = "/health/"
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for container logs."
  type        = number
  default     = 30
}

# ---------------------------------------------------------------------- tls

variable "certificate_arn" {
  description = "ACM certificate ARN. When set, the ALB serves HTTPS on 443 and redirects 80 -> 443. When empty, HTTP only."
  type        = string
  default     = ""
}

variable "app_domain" {
  description = "Public hostname for the app. When empty, the ALB DNS name is used for ALLOWED_HOSTS."
  type        = string
  default     = ""
}

# --------------------------------------------------------------------- rds

variable "db_engine_version" {
  description = "PostgreSQL major version."
  type        = string
  default     = "17"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "Initial storage in GiB."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Storage autoscaling ceiling in GiB."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Initial database name."
  type        = string
  default     = "django"
}

variable "db_username" {
  description = "Master username."
  type        = string
  default     = "django"
}

variable "db_multi_az" {
  description = "Run RDS across two AZs. Roughly doubles database cost."
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "Automated backup retention in days."
  type        = number
  default     = 7
}

variable "db_deletion_protection" {
  description = "Block `tofu destroy` from deleting the database."
  type        = bool
  default     = true
}

# ------------------------------------------------------------------- github

variable "github_repository" {
  description = "GitHub repo allowed to assume the deploy role, as \"owner/name\"."
  type        = string

  validation {
    condition     = can(regex("^[^/]+/[^/]+$", var.github_repository))
    error_message = "github_repository must be in \"owner/name\" form."
  }
}

variable "github_deploy_ref" {
  description = "Git ref subject allowed to assume the deploy role. Use \"ref:refs/heads/main\" or \"environment:production\"."
  type        = string
  default     = "ref:refs/heads/main"
}

variable "create_github_oidc_provider" {
  description = "Create the GitHub OIDC provider. Set false if the account already has one."
  type        = bool
  default     = true
}

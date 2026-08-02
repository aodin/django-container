data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  name       = "${var.project}-${var.environment}"
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  azs        = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  enable_https = var.certificate_arn != ""

  # Hosts Django will accept. The ALB DNS name is always included so the stack
  # is reachable before DNS is pointed at it.
  allowed_hosts = compact([var.app_domain, aws_lb.this.dns_name])

  csrf_origins = compact([
    var.app_domain != "" ? "https://${var.app_domain}" : "",
    "${local.enable_https ? "https" : "http"}://${aws_lb.this.dns_name}",
  ])
}

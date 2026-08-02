output "ecr_repository_url" {
  description = "Push target for the container image."
  value       = aws_ecr_repository.app.repository_url
}

output "alb_dns_name" {
  description = "Public hostname of the load balancer. Point your CNAME here."
  value       = aws_lb.this.dns_name
}

output "app_url" {
  description = "URL the application is reachable at."
  value       = "${local.enable_https ? "https" : "http"}://${var.app_domain != "" ? var.app_domain : aws_lb.this.dns_name}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name (GitHub Actions input)."
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "ECS service name (GitHub Actions input)."
  value       = aws_ecs_service.app.name
}

output "task_definition_family" {
  description = "Task definition family (GitHub Actions input)."
  value       = aws_ecs_task_definition.app.family
}

output "github_deploy_role_arn" {
  description = "Set as the AWS_DEPLOY_ROLE_ARN repository variable in GitHub."
  value       = aws_iam_role.github_deploy.arn
}

output "migration_subnet_ids" {
  description = "Private subnets used by the one-off migration task."
  value       = aws_subnet.private[*].id
}

output "migration_security_group_id" {
  description = "Security group used by the one-off migration task."
  value       = aws_security_group.tasks.id
}

output "log_group_name" {
  description = "CloudWatch Logs group for container output."
  value       = aws_cloudwatch_log_group.app.name
}

output "db_endpoint" {
  description = "RDS endpoint, reachable only from inside the VPC."
  value       = aws_db_instance.this.endpoint
}

output "github_actions_variables" {
  description = "Copy these into GitHub repository variables (Settings > Secrets and variables > Actions > Variables)."
  value = {
    AWS_REGION          = var.aws_region
    AWS_DEPLOY_ROLE_ARN = aws_iam_role.github_deploy.arn
    ECR_REPOSITORY      = aws_ecr_repository.app.name
    ECS_CLUSTER         = aws_ecs_cluster.this.name
    ECS_SERVICE         = aws_ecs_service.app.name
    ECS_TASK_FAMILY     = aws_ecs_task_definition.app.family
    ECS_SUBNET_IDS      = join(",", aws_subnet.private[*].id)
    ECS_SECURITY_GROUP  = aws_security_group.tasks.id
    ECS_LOG_GROUP       = aws_cloudwatch_log_group.app.name
  }
}

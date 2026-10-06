output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "github_actions_role_arn" {
  description = "Put this in the AWS_ROLE_ARN GitHub secret"
  value       = aws_iam_role.gha_deploy.arn
}

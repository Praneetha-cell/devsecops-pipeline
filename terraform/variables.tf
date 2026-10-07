variable "region" {
  type    = string
  default = "ap-south-1"
}

variable "project" {
  type    = string
  default = "devsecops"
}

variable "kubernetes_version" {
  type    = string
  default = "1.31"
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "github_repo" {
  type        = string
  description = "GitHub repo allowed to deploy, as owner/name"
}

variable "api_allowed_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach the public EKS API endpoint. No default on purpose: set it explicitly in terraform.tfvars. GitHub-hosted runners use wide, changing IP ranges, so for the CI deploy job use a self-hosted runner with a fixed IP, or accept a wider range knowingly."
}

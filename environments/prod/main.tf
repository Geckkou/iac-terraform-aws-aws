module "eks" {
  source = "../../../../Terraform-Collection/iac-terraform-aws-eks"

  ## PROJECT CONFIGURATION
  cluster_name  = var.cluster_name
  resource_tags = var.resource_tags


  ## CLOUDWATCH CONFIGURATION
  cluster_log_retention_in_days = var.cluster_log_retention_in_days
  scaling_period                = var.scaling_period


  ## NETWORK CONFIGURATION
  vpc_filter_key            = var.vpc_filter_key
  vpc_filter                = var.vpc_filter
  private_subnet_filter_key = var.private_subnet_filter_key
  private_subnet_filter     = var.private_subnet_filter


  ## SECURITY GROUP CONFIGURATION
  ingress_cidrs = var.ingress_cidrs
  ingress_ports = var.ingress_ports
  egress_cidrs  = var.egress_cidrs
  egress_ports  = var.egress_ports


  ## CLUSTER CONFIGURATION
  cluster     = var.cluster
  auto_mode   = var.auto_mode
  node_groups = var.node_groups
  eks_addons  = var.eks_addons

  cluster_admins = [data.aws_caller_identity.current.arn]


  ## IAM CONFIGURATION
  additional_iam_policy_arns = var.additional_iam_policy_arns
}

## PROJECT CONFIGURATION
aws_region   = "us-east-1"
cluster_name = "eks-prod"


## RESOURCE TAGS
resource_tags = {
  Owner         = "User"
  Environment   = "Prod"
  Application   = "EKS"
  Name          = "EKS-Module"
  ApplicationId = "NA"
  ManagedBy     = "Terraform"
}


## CLOUDWATCH CONFIGURATION
cluster_log_retention_in_days = 30
scaling_period                = [600, 1200, 1800]


## NETWORK CONFIGURATION
vpc_filter_key            = "Name"
vpc_filter                = "vpc-prod"
private_subnet_filter_key = "Tier"
private_subnet_filter     = "private"


## SECURITY GROUP CONFIGURATION
ingress_cidrs = ["10.0.0.0/8"]
ingress_ports = [443]
egress_cidrs  = ["0.0.0.0/0"]
egress_ports  = [0]


## CLUSTER CONFIGURATION
cluster = {
  version                   = "1.35"
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  endpoint_private_access   = true
  endpoint_public_access    = false
  service_ipv4_cidr         = "172.20.0.0/16"
}

node_groups = {}

auto_mode = {
  enabled    = true
  node_pools = ["general-purpose", "system"]
}

eks_addons = {
  CSI = {
    addon_name = "aws-ebs-csi-driver"
  }
  CNI = {
    addon_name = "vpc-cni"
  }
  KUBE-PROXY = {
    addon_name = "kube-proxy"
  }
  COREDNS = {
    addon_name = "coredns"
  }
}


## IAM CONFIGURATION
additional_iam_policy_arns = []

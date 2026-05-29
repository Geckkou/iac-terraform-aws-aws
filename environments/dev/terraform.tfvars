##PROJECT CONFIGURATION
cluster_name = "eks"
aws_region   = "us-east-1"


## RESOURCE TAGS
resource_tags = {
  Owner         = "Alexandre"
  Environment   = "NoProd"
  Application   = "EKS"
  Name          = "EKS-Module"
  ApplicationId = "NA"
  ManagedBy     = "Terraform"
}


## CLOUDWATCH CONFIGURATION
cluster_log_retention_in_days = 7
scaling_period                = [600, 1200, 1800]


## NETWORK CONFIGURATION
vpc_filter_key            = "Name"
vpc_filter                = "Default"
private_subnet_filter_key = "Public"
private_subnet_filter     = "true"


## SECURITY GROUP CONFIGURATION
ingress_cidrs = ["10.0.0.0/8"]
ingress_ports = [443]
egress_cidrs  = ["0.0.0.0/0"]
egress_ports  = [0]


## Cluster Configuration
cluster = {
  version                   = "1.35"
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  endpoint_private_access   = false
  endpoint_public_access    = true
  service_ipv4_cidr         = "172.20.0.0/16"
}

node_groups = {
  infra = {
    desired_size = 3
    min_size     = 3
    max_size     = 6
    labels = {
      Role = "worker"
    }

    capacity_type  = "ON_DEMAND"
    ami_id         = "" #amazon-eks-node-al2023-x86_64-standard-1.34-v20251007
    instance_types = ["t3a.large"]
    device_name    = "/dev/xvda"
    volume_type    = "gp3"
    volume_size    = 20
  }
}


## AUTO MODE CONFIGURATION
auto_mode = {
  enabled    = true
  node_pools = ["general-purpose", "system"]
}


## EKS ADDONS
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
    addon_name    = "coredns"
    addon_version = "v1.14.2-eksbuild.4"
  }
}


## IAM CONFIGURATION
additional_iam_policy_arns = []
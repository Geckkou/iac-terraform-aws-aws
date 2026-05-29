## PROJECT CONFIGURATION
variable "aws_region" {
  description = "AWS region where the cluster will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Nome que será usado na criação de alguns recursos e do Launch Template"
  type        = string
}


## RESOURCE TAGS
variable "resource_tags" {
  description = "Tags to set for all resources"
  type        = map(string)
  default = {
    Owner         = "User"
    Environment   = "NoProd"
    Application   = "EKS"
    Name          = "EKS-Module"
    ApplicationId = "NA"
    ManagedBy     = "Terraform"
  }

  validation {
    condition = length(setsubtract([
      "Owner",
      "Environment",
      "Application",
      "Name",
      "ApplicationId",
      "ManagedBy",
    ], keys(var.resource_tags))) == 0
    error_message = "The resource_tags map must contain all the required keys."
  }
}


## CLOUDWATCH CONFIGURATION
variable "cluster_log_retention_in_days" {
  description = "Tempo de vida dos logs definido em dias."
  type        = number
}

variable "scaling_period" {
  description = "Cooldown periods for ASG scaling policies (seconds). Obrigatório quando auto_mode.enabled = false."
  type        = set(number)
  default     = null

  validation {
    condition     = var.scaling_period == null || alltrue([for p in var.scaling_period : p >= 60])
    error_message = "scaling_period values must be >= 60 seconds"
  }
}


## NETWORK CONFIGURATION
variable "vpc_filter_key" {
  description = "VPC tag:(value) Valor para achar uma VPC através de um Data com chave de tag."
  type        = string
}

variable "vpc_filter" {
  description = "Valor de tag VPC para achar a VPC através de um Data com valor de tag."
  type        = string
}

variable "private_subnet_filter_key" {
  description = "Subnet tag:(value) Valor para achar uma Subnet através de um Data com chave de tag."
  type        = string
}

variable "private_subnet_filter" {
  description = "Valor de tag Subnet para achar a Subnet através de um Data com valor de tag."
  type        = string
}


## SECURITY GROUP CONFIGURATION
variable "ingress_cidrs" {
  description = "Lista de blocos CIDR permitidos para o endpoint do servidor."
  type        = list(string)

  validation {
    condition     = join(",", var.ingress_cidrs) != join(",", ["0.0.0.0/0"])
    error_message = "Invalid cidrs, public blocks are not allowed."
  }
}

variable "ingress_ports" {
  description = "Lista de portas de entrada personalizadas que podem acessar o endpoint do servidor."
  type        = list(number)
}

variable "egress_cidrs" {
  description = "Lista de blocos CIDRs permitidos no tráfego de saída."
  type        = list(string)
}

variable "egress_ports" {
  description = "Lista de portas de saida personalizadas que podem acessar o endpoint do servidor."
  type        = list(number)
}


## CLUSTER CONFIGURATION
variable "node_groups" {
  description = "Mapa de configuração do NodeGroup. Obrigatório quando auto_mode.enabled = false."
  type = map(object({
    desired_size   = number
    min_size       = number
    max_size       = number
    labels         = map(string)
    capacity_type  = string
    ami_id         = optional(string)
    instance_types = list(string)
    device_name    = string
    volume_type    = string
    volume_size    = number
  }))
  default = {}

  validation {
    condition = alltrue([
      for ng in values(var.node_groups) :
      ng.min_size <= ng.desired_size && ng.desired_size <= ng.max_size
    ])
    error_message = "min_size <= desired_size <= max_size must be respected"
  }

  validation {
    condition = alltrue([
      for ng in values(var.node_groups) :
      contains(["ON_DEMAND", "SPOT"], ng.capacity_type)
    ])
    error_message = "capacity_type must be ON_DEMAND or SPOT"
  }

  validation {
    condition = alltrue([
      for ng in values(var.node_groups) :
      ng.volume_size >= 20
    ])
    error_message = "Root volume size must be at least 20GiB"
  }
}

variable "auto_mode" {
  description = "Configuração do EKS Auto Mode. Quando enabled = true, o AWS gerencia o compute automaticamente — node_groups e scaling_period não são necessários."
  type = object({
    enabled    = bool
    node_pools = optional(list(string), ["general-purpose", "system"])
  })
  default = {
    enabled = false
  }
}

variable "cluster" {
  description = "Mapa de configuração do Cluster"
  type = object({
    version                   = string
    enabled_cluster_log_types = list(string)
    endpoint_private_access   = bool
    endpoint_public_access    = bool
    service_ipv4_cidr         = string
  })
}

variable "eks_addons" {
  description = "Mapa de EKS addons a serem instalados no cluster"
  type = map(object({
    addon_name               = string
    addon_version            = optional(string)
    configuration_values     = optional(string)
    service_account_role_arn = optional(string)
    resolve_conflicts        = optional(string, "OVERWRITE")
  }))

  default = {
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
}


## IAM CONFIGURATION
variable "additional_iam_policy_arns" {
  description = "List of addicional IAM policies ARNs for the Workers Node Instance Profile"
  type        = list(string)
}

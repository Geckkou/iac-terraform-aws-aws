# iac-terraform-aws-eks

Infraestrutura do cluster Amazon EKS gerenciada via Terraform, organizada por ambiente.

## Estrutura

```
EKS/
├── environments/
│   ├── dev/                    # Ambiente de desenvolvimento / homologação
│   │   ├── backend.tf          # Remote state S3
│   │   ├── data.tf             # Data sources (caller identity)
│   │   ├── main.tf             # Chama o módulo EKS
│   │   ├── provider.tf         # Provider AWS com default_tags
│   │   ├── variables.tf        # Declaração das variáveis
│   │   ├── versions.tf         # Versões do Terraform e providers
│   │   └── terraform.tfvars    # Valores do ambiente dev
│   └── prod/                   # Ambiente de produção
│       ├── backend.tf
│       ├── data.tf
│       ├── main.tf
│       ├── provider.tf
│       ├── variables.tf
│       ├── versions.tf
│       └── terraform.tfvars    # Valores do ambiente prod
└── README.md
```

O módulo EKS reutilizável está em `../Terraform-Collection/iac-terraform-aws-eks`.

---

## Pré-requisitos

| Ferramenta | Versão mínima |
|---|---|
| Terraform | >= 1.9.0 |
| AWS CLI | >= 2.x |
| kubectl | >= 1.28 |
| aws provider | ~> 6.47.0 |

Credenciais AWS configuradas com permissões para criar EKS, EC2, IAM e VPC.

---

## Como usar

**1 — Configure as credenciais AWS**

```bash
aws configure
# ou SSO:
aws sso login --profile <profile>
```

**2 — Inicialize e aplique o ambiente desejado**

```bash
cd environments/dev    # ou environments/prod

terraform init
terraform plan
terraform apply
```

**3 — Configure o kubeconfig após o apply**

```bash
aws eks update-kubeconfig \
  --name <cluster_name> \
  --region <aws_region>

kubectl get nodes
```

---

## Variáveis principais

| Variável | Descrição | Obrigatório |
|---|---|:---:|
| `aws_region` | Região AWS do cluster | não (default: `us-east-1`) |
| `cluster_name` | Nome do cluster e recursos relacionados | sim |
| `cluster` | Versão, logs, acesso ao endpoint, CIDR de serviços | sim |
| `auto_mode` | Habilita EKS Auto Mode (AWS gerencia o compute) | não (default: `false`) |
| `node_groups` | Configuração dos Node Groups (ignorado se `auto_mode.enabled = true`) | não (default: `{}`) |
| `eks_addons` | Addons instalados no cluster | não (defaults incluídos) |
| `scaling_period` | Cooldown do ASG em segundos (necessário quando Auto Mode desabilitado) | não |
| `vpc_filter_key` / `vpc_filter` | Filtro de tag para localizar a VPC via data source | sim |
| `private_subnet_filter_key` / `private_subnet_filter` | Filtro de tag para localizar as subnets privadas | sim |
| `ingress_cidrs` | CIDRs com acesso ao endpoint da API (blocos públicos não permitidos) | sim |
| `resource_tags` | Tags aplicadas a todos os recursos (Owner, Environment, Application, Name, ApplicationId, ManagedBy) | não (defaults incluídos) |
| `additional_iam_policy_arns` | ARNs de políticas IAM adicionais para o Instance Profile dos workers | sim |

---

## EKS Auto Mode vs Node Groups

| | Auto Mode | Node Groups |
|---|---|---|
| Gerenciamento do compute | AWS (automático) | Você (via Terraform) |
| Auto Scaling Group | Não criado | Criado |
| Escala por demanda de pods | Sim | Não (fixo) |
| `node_groups` necessário | Não | Sim |
| `scaling_period` necessário | Não | Sim |

Quando `auto_mode.enabled = true`, as configurações de `node_groups` e `scaling_period` são ignoradas pelo módulo.

---

## Remote State

| Ambiente | Bucket | Key |
|---|---|---|
| dev | `vtg-alexandre-terraform-state` | `eks-github-actions/terraform.tfstate` |
| prod | `vtg-alexandre-terraform-state` | `eks/prod/terraform.tfstate` |

O bucket S3 precisa existir antes do `terraform init`. O lock de estado é gerenciado pelo próprio S3 (`use_lockfile = true`).

---

## Addons padrão

| Addon | Nome |
|---|---|
| CSI | `aws-ebs-csi-driver` |
| CNI | `vpc-cni` |
| Kube Proxy | `kube-proxy` |
| CoreDNS | `coredns` |

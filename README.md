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
| prod | `vtg-alexandre-terraform-state` | `eks-github-actions-prod/terraform.tfstate` |

O bucket S3 precisa existir antes do `terraform init`. O lock de estado é gerenciado pelo próprio S3 (`use_lockfile = true`).

---

## Addons padrão

| Addon | Nome |
|---|---|
| CSI | `aws-ebs-csi-driver` |
| CNI | `vpc-cni` |
| Kube Proxy | `kube-proxy` |
| CoreDNS | `coredns` |

---

## CI/CD — GitHub Actions

Os workflows estão em `.github/workflows/`:

| Workflow | Trigger | Função |
|---|---|---|
| `ci.yml` | Pull Request → `main` | Validate + Security Scan + Plan (comentário no PR) |
| `cd.yml` | Push em `main` ou dispatch manual | Plan + Deploy com gates de aprovação |

### Fluxo completo

```
Pull Request
  └── validate (dev + prod)   fmt, init -backend=false, validate, tflint
  └── security (dev + prod)   Checkov + tfsec
        └── plan-dev           terraform plan → comentário no PR
        └── plan-prod          terraform plan → comentário no PR

Merge em main
  └── plan-dev
        └── deploy-dev  [gate: Environment "dev"]
              └── plan-prod
                    └── deploy-prod  [gate: Environment "prod" + aprovação manual]
```

### Ferramentas de segurança (gratuitas)

| Ferramenta | Foco | Action |
|---|---|---|
| [Checkov](https://github.com/bridgecrewio/checkov) | CIS, NIST, SOC2 — ampla cobertura IaC | `bridgecrewio/checkov-action@v12` |
| [tfsec](https://github.com/aquasecurity/tfsec) | Regras específicas para Terraform/AWS | `aquasecurity/tfsec-action@v1.0.0` |

---

## Configuração do CI/CD (pré-requisitos)

### 1 — Criar o OIDC Provider na AWS

Executar **uma única vez** por conta AWS. Permite que o GitHub Actions assuma roles IAM sem credenciais estáticas.

```bash
aws iam create-open-id-connect-provider \
  --url "https://token.actions.githubusercontent.com" \
  --client-id-list 'sts.amazonaws.com'
```

> A partir de dezembro/2024 o `--thumbprint-list` não é mais necessário — a AWS gerencia automaticamente.

### 2 — Criar as IAM Roles

Criar **uma role por context** de acordo com os jobs dos workflows. A AWS recomenda `StringEquals` com o subject exato — evitar wildcards (`*`) para reduzir a superfície de ataque.

Substitua `SEU-ORG` e `SEU-REPO` pelo org e repositório do GitHub.

#### Roles necessárias

| Role sugerida | Usado em | Subject (`sub`) |
|---|---|---|
| `eks-plan-dev` | CI: plan dev (PR) | `repo:SEU-ORG/SEU-REPO:pull_request` |
| `eks-plan-prod` | CI: plan prod (PR) | `repo:SEU-ORG/SEU-REPO:pull_request` |
| `eks-deploy-dev` | CD: deploy dev | `repo:SEU-ORG/SEU-REPO:environment:dev` |
| `eks-deploy-prod` | CD: deploy prod | `repo:SEU-ORG/SEU-REPO:environment:prod` |

> Se preferir simplificar, as roles de plan e deploy do mesmo ambiente podem ser a mesma role — basta usar `StringLike` com `repo:SEU-ORG/SEU-REPO:*`. O trade-off é uma superfície de ataque maior.

#### Trust policy (exemplo para `eks-deploy-prod`)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:SEU-ORG/SEU-REPO:environment:prod"
        }
      }
    }
  ]
}
```

Troque o `sub` conforme a tabela acima para cada role. O campo `aud` é sempre `sts.amazonaws.com`.

### 3 — Secrets no GitHub

**Repository secrets** (`Settings > Secrets and variables > Actions`):

| Secret | Role | Usado em |
|---|---|---|
| `AWS_ROLE_ARN_DEV` | `eks-plan-dev` | CI: job `plan-dev` (PR) |
| `AWS_ROLE_ARN_PROD` | `eks-plan-prod` | CI: job `plan-prod` (PR) |

**Environment secrets** (`Settings > Environments > <env> > Secrets`):

| Environment | Secret | Role | Usado em |
|---|---|---|---|
| `dev` | `AWS_ROLE_ARN` | `eks-deploy-dev` | CD: job `deploy-dev` |
| `prod` | `AWS_ROLE_ARN` | `eks-deploy-prod` | CD: job `deploy-prod` |

### 4 — Criar os Environments no GitHub

Em `Settings > Environments`:

- **`dev`** — adicione reviewers se quiser aprovação antes do deploy
- **`prod`** — adicione **Required reviewers** para habilitar o gate de aprovação manual

### 5 — Ajustar o `source` do módulo

O path local `../../../Terraform-Collection/...` não funciona em runners de CI.
Substitua pelo git URL do módulo nos arquivos `environments/*/main.tf`:

```hcl
module "eks" {
  source = "git::https://github.com/SEU-ORG/iac-terraform-aws-eks.git?ref=v1.0.0"
  # ...
}
```

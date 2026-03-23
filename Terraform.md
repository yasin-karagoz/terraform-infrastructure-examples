# Terraform Guide

Detailed explanations of Terraform concepts with practical examples.

---

## Table of Contents

1. [Intro to Terraform](#intro-to-terraform)
2. [Terraform Commands](#terraform-commands)
3. [Terraform Versions](#terraform-versions)
4. [Terraform CLI](#terraform-cli)
5. [Providers](#providers)
6. [Provider Aliases](#provider-aliases)
7. [Modules](#modules)
8. [Terraform Files](#terraform-files)
9. [Variable Types](#variable-types)
10. [Locals](#locals)
11. [Block Types](#block-types)
12. [Data Sources](#data-sources)
13. [Dependencies](#dependencies)
14. [count vs for_each](#count-vs-for_each)
15. [Dynamic Blocks](#dynamic-blocks)
16. [Lifecycle Meta-Argument](#lifecycle-meta-argument)
17. [Provisioners](#provisioners)
18. [Backend Types](#backend-types)
19. [State](#terraform-state)
20. [State Locking](#state-locking)
21. [State Migration](#state-migration)
22. [Workspaces](#workspaces)
23. [Environment Variables](#environment-variables)
24. [required_providers](#required_providers)
25. [Vault Integration](#vault-integration)
26. [Sentinel](#sentinel)
27. [Supported OS](#supported-os)

---

## Intro to Terraform

Terraform is an open-source Infrastructure as Code (IaC) tool by HashiCorp. It lets you define and provision infrastructure using a declarative configuration language (HCL), and works across AWS, GCP, Azure, and hundreds of other providers.

```hcl
provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

---

## Terraform Commands

Commands for managing the full lifecycle of infrastructure.

| Command | Description |
|---|---|
| `terraform init` | Initializes the working directory, downloads providers and modules |
| `terraform fmt` | Formats `.tf` files to the canonical HCL style |
| `terraform validate` | Validates configuration syntax and internal consistency |
| `terraform plan` | Shows what changes will be made without applying them |
| `terraform apply` | Applies changes to reach the desired state |
| `terraform destroy` | Destroys all managed infrastructure |
| `terraform output` | Reads and displays output values from state |
| `terraform show` | Shows the current state or a saved plan in human-readable form |
| `terraform import` | Imports existing infrastructure into Terraform state |
| `terraform state list` | Lists all resources in the state |
| `terraform state mv` | Moves a resource to a new address in state |
| `terraform state rm` | Removes a resource from state (without destroying it) |

```sh
# Format and validate before every plan
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

---

## Terraform Versions

- **Terraform OSS** — Free, open-source CLI. Runs locally or in your own CI/CD.
- **Terraform Cloud** — Managed SaaS with remote state, remote runs, and team collaboration.
- **Terraform Enterprise** — Self-hosted version of Terraform Cloud. Adds SSO, audit logs, and Sentinel policy enforcement.

---

## Terraform CLI

```sh
terraform --version

# Initialize (always run first, or after adding new providers/modules)
terraform init

# Preview changes
terraform plan

# Apply with auto-approval (useful in CI, use carefully)
terraform apply -auto-approve

# Target a specific resource
terraform apply -target=aws_instance.example

# Destroy a specific resource
terraform destroy -target=aws_instance.example
```

---

## Providers

Providers are plugins that implement resource types for a specific platform (AWS, GCP, Azure, etc.). They handle all API interactions.

```hcl
# AWS provider
provider "aws" {
  region = "us-west-2"
}

# GCP provider
provider "google" {
  project = "my-gcp-project"
  region  = "us-central1"
}

# Azure provider
provider "azurerm" {
  features {}
}
```

---

## Provider Aliases

Use aliases when you need multiple configurations of the same provider — for example, deploying to two different AWS regions or GCP projects.

```hcl
provider "aws" {
  region = "us-west-2"
  alias  = "west"
}

provider "aws" {
  region = "us-east-1"
  alias  = "east"
}

# Reference the alias with provider = <name>.<alias>
resource "aws_instance" "west_instance" {
  provider      = aws.west
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

resource "aws_instance" "east_instance" {
  provider      = aws.east
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

---

## Modules

Modules are reusable, self-contained packages of Terraform configuration. They help you avoid repetition and enforce consistency.

- **Public modules** — Available on the [Terraform Registry](https://registry.terraform.io).
- **Private modules** — Stored in private Git repos or a private Terraform Cloud registry.

```hcl
# Public module from the Terraform Registry
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
  azs  = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

# Private module from a Git repo
module "internal_service" {
  source = "git::https://github.com/your-org/terraform-modules.git//service?ref=v1.2.0"

  name = "api"
}
```

Access outputs from a module with `module.<name>.<output>`:

```hcl
output "vpc_id" {
  value = module.vpc.vpc_id
}
```

---

## Terraform Files

Standard file layout for a Terraform project:

```
project/
├── main.tf          # Core resources
├── variables.tf     # Input variable declarations
├── outputs.tf       # Output value declarations
├── providers.tf     # Provider configuration
├── versions.tf      # required_providers and required_version
├── locals.tf        # Local values (optional)
└── terraform.tfvars # Variable values (do not commit secrets)
```

For larger projects, split by concern (`network.tf`, `iam.tf`, `compute.tf`, etc.).

---

## Variable Types

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "instance_count" {
  description = "Number of instances to create"
  type        = number
  default     = 1
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = false
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default = {
    environment = "dev"
    managed-by  = "terraform"
  }
}

variable "db_config" {
  description = "Database configuration object"
  type = object({
    engine  = string
    version = string
    port    = number
  })
  default = {
    engine  = "postgres"
    version = "14"
    port    = 5432
  }
}
```

---

## Locals

Locals let you define reusable expressions and computed values within a module. They reduce repetition and keep complex expressions out of resource blocks.

```hcl
locals {
  name_prefix = "${var.environment}-${var.project}"
  common_tags = merge(var.tags, {
    environment = var.environment
    managed-by  = "terraform"
  })
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web"
  })
}
```

---

## Block Types

```hcl
# terraform block — version constraints and backend
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# provider block — configures a provider
provider "aws" {
  region = "us-west-2"
}

# resource block — declares a managed resource
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

# data block — fetches read-only data from a provider
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}

# variable block — declares an input variable
variable "region" {
  type    = string
  default = "us-west-2"
}

# output block — exposes a value after apply
output "instance_id" {
  value = aws_instance.example.id
}

# module block — calls a reusable module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"
  name    = "my-vpc"
  cidr    = "10.0.0.0/16"
}
```

---

## Data Sources

Data sources let you fetch information from external sources or from resources not managed by this configuration.

```hcl
# Fetch the latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-22.04-amd64-server-*"]
  }
}

# Use the fetched AMI ID in a resource
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
}
```

```hcl
# Fetch an existing VPC by tag
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["production-vpc"]
  }
}
```

---

## Dependencies

### Implicit Dependencies

Terraform automatically determines order by analyzing references between resources. If resource B references an attribute of resource A, Terraform creates A first.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}

# aws_eip implicitly depends on aws_instance.web because it references its id
resource "aws_eip" "web_ip" {
  instance = aws_instance.web.id
}
```

### Explicit Dependencies (`depends_on`)

Use `depends_on` when a dependency exists that Terraform can't infer from the configuration — for example, when one resource needs a policy to exist before it can function, even though it doesn't reference it directly.

```hcl
resource "aws_iam_role_policy" "example" {
  role   = aws_iam_role.example.id
  policy = data.aws_iam_policy_document.example.json
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  # The instance needs the IAM policy to exist before it can call AWS APIs
  depends_on = [aws_iam_role_policy.example]
}
```

---

## count vs for_each

Both meta-arguments let you create multiple resource instances. Use `for_each` when instances have distinct identities; use `count` for identical copies.

### `count` — index-based

```hcl
variable "instance_count" {
  default = 3
}

resource "aws_instance" "web" {
  count         = var.instance_count
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "web-${count.index}"
  }
}

# Reference: aws_instance.web[0], aws_instance.web[1], ...
```

**Drawback:** If you remove an item from the middle of the list, Terraform re-indexes and destroys/recreates subsequent resources.

### `for_each` — key-based (preferred)

```hcl
variable "instances" {
  type = map(object({
    ami           = string
    instance_type = string
  }))
  default = {
    web = { ami = "ami-0c55b159cbfafe1f0", instance_type = "t2.micro" }
    api = { ami = "ami-0c55b159cbfafe1f0", instance_type = "t2.small" }
  }
}

resource "aws_instance" "servers" {
  for_each = var.instances

  ami           = each.value.ami
  instance_type = each.value.instance_type

  tags = {
    Name = each.key
  }
}

# Reference: aws_instance.servers["web"], aws_instance.servers["api"]
```

**Advantage:** Removing one key only affects that specific resource, not others.

---

## Dynamic Blocks

`dynamic` blocks let you generate repeated nested blocks (like `ingress` rules in a security group) from a variable list instead of hardcoding each one.

```hcl
variable "ingress_rules" {
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    { port = 80,  protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { port = 443, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] },
    { port = 22,  protocol = "tcp", cidr_blocks = ["10.0.0.0/8"] },
  ]
}

resource "aws_security_group" "web" {
  name = "web-sg"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

---

## Lifecycle Meta-Argument

The `lifecycle` block controls how Terraform creates, updates, and destroys resources.

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  lifecycle {
    # Create the replacement before destroying the old one (zero-downtime updates)
    create_before_destroy = true

    # Prevent accidental destruction of this resource
    prevent_destroy = true

    # Ignore changes to these attributes (e.g., if an external process sets them)
    ignore_changes = [
      ami,
      tags["LastModified"],
    ]

    # Trigger a replacement when this expression changes (Terraform 1.2+)
    replace_triggered_by = [
      aws_security_group.web.id
    ]
  }
}
```

### `moved` Block (Terraform 1.1+)

Rename or move a resource in your config without destroying and recreating it.

```hcl
# Rename aws_instance.old_name to aws_instance.new_name in state
moved {
  from = aws_instance.old_name
  to   = aws_instance.new_name
}
```

---

## Provisioners

Provisioners run scripts after a resource is created. They are a **last resort** — prefer cloud-init, Packer images, or configuration management tools. Terraform has no way to track provisioner state.

### `local-exec`

Runs a command on the machine running Terraform.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  provisioner "local-exec" {
    command = "echo Instance ${self.id} created at IP ${self.public_ip} >> inventory.txt"
  }
}
```

### `remote-exec`

Runs commands on the newly created remote resource over SSH or WinRM.

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y nginx",
      "sudo systemctl enable nginx",
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
}
```

---

## Backend Types

Backends determine where Terraform stores its state file. Remote backends also enable state locking and team collaboration.

| Backend | Notes |
|---|---|
| `local` | Default. State stored on disk. No locking. |
| `s3` | AWS S3. Use with DynamoDB for locking. |
| `gcs` | Google Cloud Storage. Built-in locking. |
| `azurerm` | Azure Blob Storage. Built-in locking. |
| `http` | Generic HTTP backend. |
| `terraform cloud` | Managed by Terraform Cloud/Enterprise. |

```hcl
# Local backend (default)
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

```hcl
# S3 backend with DynamoDB state locking
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
```

```hcl
# GCS backend
terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "prod"
  }
}
```

```hcl
# Terraform Cloud backend
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      name = "my-workspace"
    }
  }
}
```

---

## Terraform State

The state file (`terraform.tfstate`) maps your configuration to real-world resources. Terraform uses it to determine what needs to change on each `plan`/`apply`.

**Never edit the state file manually.** Use `terraform state` commands instead.

```sh
# List all resources in state
terraform state list

# Show details of a specific resource
terraform state show aws_instance.web

# Move a resource to a new address (e.g., after renaming)
terraform state mv aws_instance.web aws_instance.api

# Remove a resource from state without destroying it
terraform state rm aws_instance.web

# Import an existing resource into state
terraform import aws_instance.web i-0abcd1234efgh5678
```

Example state file structure:

```json
{
  "version": 4,
  "terraform_version": "1.5.0",
  "resources": [
    {
      "type": "aws_instance",
      "name": "example",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "attributes": {
            "id": "i-0abcd1234efgh5678",
            "ami": "ami-0c55b159cbfafe1f0",
            "instance_type": "t2.micro"
          }
        }
      ]
    }
  ]
}
```

---

## State Locking

State locking prevents concurrent operations from corrupting the state file. When you run `terraform apply`, Terraform acquires a lock and releases it when done.

| Backend | Lock Mechanism |
|---|---|
| S3 | DynamoDB table |
| GCS | Built-in GCS object locking |
| Azure | Built-in blob leases |
| Terraform Cloud | Built-in |

```sh
# If a lock gets stuck (e.g., after a crash), force-unlock it
# Get the lock ID from the error message
terraform force-unlock <LOCK_ID>
```

---

## State Migration

Move state from one backend to another without touching real infrastructure.

```sh
# 1. Update the backend block in your config
# 2. Run init with the migrate flag
terraform init -migrate-state
```

---

## Workspaces

Workspaces let you manage multiple independent state files from the same configuration — useful for per-environment deployments (dev, staging, prod).

```sh
# Create and switch to a new workspace
terraform workspace new dev

# List all workspaces
terraform workspace list

# Switch workspace
terraform workspace select prod

# Show current workspace
terraform workspace show

# Delete a workspace
terraform workspace delete dev
```

Reference the current workspace in your configuration:

```hcl
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = terraform.workspace == "prod" ? "t2.large" : "t2.micro"

  tags = {
    Environment = terraform.workspace
  }
}
```

---

## Environment Variables

```sh
# Set Terraform log level: TRACE, DEBUG, INFO, WARN, ERROR
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log

# Pass variable values via environment (TF_VAR_<name>)
export TF_VAR_region="us-west-2"
export TF_VAR_instance_type="t2.small"

# AWS credentials
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="us-west-2"

# GCP credentials
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

# Disable color output (useful in CI)
export TF_CLI_ARGS="-no-color"

# Automatically approve applies (use carefully)
export TF_CLI_ARGS_apply="-auto-approve"
```

---

## required_providers

Pin provider versions to prevent unexpected changes when providers release breaking updates.

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # allows 5.x, blocks 6.0
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0, < 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}
```

Version constraint operators:

| Operator | Meaning |
|---|---|
| `= 1.0.0` | Exact version only |
| `>= 1.0.0` | Any version 1.0.0 or higher |
| `~> 1.5` | Any version in the 1.x range (pessimistic) |
| `~> 1.5.0` | Any version 1.5.x |
| `>= 1.0, < 2.0` | Range |

---

## Vault Integration

HashiCorp Vault stores secrets (API keys, passwords, certs). Terraform's Vault provider fetches secrets at runtime so they never need to be hardcoded.

```hcl
provider "vault" {
  address = "https://vault.example.com"
  # Auth is handled via VAULT_TOKEN env variable or other auth methods
}

# Fetch a secret from Vault
data "vault_generic_secret" "db" {
  path = "secret/database/prod"
}

resource "aws_db_instance" "main" {
  engine   = "postgres"
  username = data.vault_generic_secret.db.data["username"]
  password = data.vault_generic_secret.db.data["password"]
  # ...
}
```

---

## Sentinel

Sentinel is a policy-as-code framework for Terraform Cloud/Enterprise. It lets you enforce rules on configurations before `apply` runs — for example, preventing resources without required tags or blocking public S3 buckets.

```hcl
# Sentinel policy: require all EC2 instances to have an "environment" tag
import "tfplan/v2" as tfplan

get_ec2_instances = func() {
  return filter tfplan.resource_changes as _, rc {
    rc.type is "aws_instance" and rc.mode is "managed"
  }
}

require_environment_tag = rule {
  all get_ec2_instances() as _, instance {
    instance.change.after.tags["environment"] is not null
  }
}

main = rule {
  require_environment_tag
}
```

Policies are applied in enforcement levels:
- **advisory** — warns but does not block
- **soft-mandatory** — blocks unless overridden by a privileged user
- **hard-mandatory** — always blocks

---

## Supported OS

Terraform CLI runs on Windows, macOS, and Linux.

```sh
# macOS (Homebrew)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Ubuntu / Debian
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Windows (Chocolatey)
choco install terraform

# Verify
terraform --version
```

# terraform-aws-eks-windows

The eks windows module is based on the eks module v20.x.x

I want to provide the easy ways for you to install the eks windows

## Badge

Terraform Latest Version:   
![GitHub Release](https://img.shields.io/github/v/release/mrnim94/terraform-aws-eks-windows)
 

[![SonarCloud](https://sonarcloud.io/images/project_badges/sonarcloud-white.svg)](https://sonarcloud.io/summary/new_code?id=mrnim94_terraform-aws-eks-windows)

## Install EKS windows on vpc that is created by VPC Terrform Module.

### variables.tf file

```hcl
variable "region" {
  description = "Please enter the region used to deploy this infrastructure"
  type        = string
  default = "us-east-1"
}

# Environment Variable
variable "environment" {
  description = "Environment Variable used as a prefix"
  type = string
  default = "dev"
}
# Business Division
variable "business_divsion" {
  description = "Business Division in the large organization this Infrastructure belongs"
  type = string
  default = "nimtechnology"
}

# Business Division

variable "owners" {
  description = "Business Division in the large organization this Infrastructure belongs"
  type = string
  default = "devops"
}

variable "eks_cluster_version" {
  description = "Please enter the EKS cluster version"
  type        = string
  default = "1.24"
}
```

### local-values.tf file

```
# Define Local Values in Terraform
locals {
  owners = var.owners
  environment = var.environment
  common_tags = {
    owners = local.owners
    environment = local.environment
  }
  cluster_name = "${local.environment}-${local.owners}-${var.business_divsion}"
}
```

### Create main.tf file

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.1"
    }
  }
}
provider "aws" {
  region = var.region
}

//Modify the bucket and dynamoDB table that are used by Terraform
terraform {
  backend "s3" {
    bucket         = "private-windows-nimtechnology-eks-tf-lock"
    key            = "private-windows-eks.tfstate"
    region         = "us-east-1"
    dynamodb_table = "private-windows-nimtechnology-eks-tf-lock"
  }
}

data terraform_remote_state "network" {
    backend = "s3"
    config = {
        bucket = "private-windows-nimtechnology-eks-tf-lock"
        key = "network.tfstate"
        region = "us-east-1"
     }
}


output "out_private_subnets" {
  value = data.terraform_remote_state.network.outputs.private_subnets
}

module "eks-windows" {
    source  = "mrnim94/eks-windows/aws"
    version = "2.5.1"
    region = var.region
    eks_cluster_name = local.cluster_name
    eks_cluster_version = "1.24"
    private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnets
    # public_subnet_ids = data.terraform_remote_state.network.outputs.out_public_vpc.public_subnets
    vpc_id = data.terraform_remote_state.network.outputs.vpc_id
    lin_desired_size = 2
    lin_max_size = 2
    lin_min_size = 2
    lin_instance_type = "t3.medium"
    win_desired_size = 2
    win_max_size = 2
    win_min_size = 2
    win_instance_type = "t3.xlarge"
    node_host_key_name = "eks-terraform-key"
}
```

### create output.tf   
We will install many add-ons and applications that need the EKS information such as:   
- eks_cluster_certificate_authority_data: Base64 encoded certificate data required to communicate with the cluster
- eks_cluster_endpoint: Endpoint for the EKS cluster. Used to communicate with the cluster.
- eks_cluster_name: The name of the EKS cluster
- aws_iam_openid_connect_provider_arn: ARN of the OIDC provider for the EKS cluster. Used for setting up IAM roles for service accounts.   

I suggest you create the extra "output.tf" file such as:

```hcl
# EKS cluster name
output "cluster_name" {
  description = "The name of EKS cluster"
  value       = module.eks-windows.cluster_name
}
# EKS cluster endpoint
output "cluster_endpoint" {
  description = "API server endpoint of EKS cluster"
  value       = module.eks-windows.cluster_endpoint
}
# EKS cluster certificate authority
output "cluster_certificate_authority_data" {
  description = "The certificate authority of EKS cluster"
  value       = module.eks-windows.cluster_certificate_authority_data
}
 
# EKS cluster OpenID Connect provider URL
output "oidc_provider_arn" {
  description = "The certificate authority of EKS cluster"
  value       = module.eks-windows.oidc_provider_arn
}
``` 

### Provisioning the extra node groups beside 2 default node Groups(Windows and Linux):

> You can use the **custom\_node\_groups** variable to define your desired node Groups.  
> we are enhance at: [Create the dynamic extra node group #41](https://github.com/mrnim94/terraform-aws-eks-windows/issues/41)

#### example:

```hcl
module "eks-windows" {
    source  = "mrnim94/eks-windows/aws"
    version = "3.x.x"
    region = var.region
    eks_cluster_name = local.cluster_name
    eks_cluster_version = "1.27"
    private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnets
    # public_subnet_ids = data.terraform_remote_state.network.outputs.out_public_vpc.public_subnets
    vpc_id = data.terraform_remote_state.network.outputs.vpc_id
    lin_desired_size = 2
    lin_max_size = 2
    lin_min_size = 2
    lin_instance_type = "m5.2xlarge"
    win_desired_size = 2
    win_max_size = 2
    win_min_size = 1
    win_instance_type = "t3.xlarge"
    disable_windows_defender = true
    node_host_key_name = "eks-terraform-key"


    ##look at here:
    custom_node_groups = [
      {
        name         = "windows-group"
        platform     = "windows"
        instance_type= "t3.large"
        subnet_ids   = ["subnet-04bdeb40bc6cfdc4c", "subnet-04bdeb40bc6cfdc4c"]
        min_size     = 1
        max_size     = 3
        desired_size = 2
        disable_windows_defender = true
        taints = [
          {
            key    = "os"
            value  = "windows"
            effect = "NO_SCHEDULE"
          }
        ]
        labels = {
          "os" = "windows"
        }
      }
    ]

}
```

#### explain:   
the details of the custom_node_groups variable

| Attribute | Type | Description |
| --- | --- | --- |
| `name` | `string` | The name of the node group. |
| `platform` | `string` | The platform of the nodes in the node group (e.g., Linux, Windows). |
| `instance_type` | `string` | The type of instance to use for the nodes in the node group. |
| `desired_size` | `number` | The desired number of nodes in the node group. |
| `subnet_ids` | `list(string)` | (Optional)The individual subnet IDs for the node group.. |
| `max_size` | `number` | The maximum number of nodes in the node group. |
| `min_size` | `number` | The minimum number of nodes in the node group. |
| `disable_windows_defender` | `bool` | (Optional, Default = `false`) Whether to disable Windows Defender on the nodes in the node group. |
| `taints` | `list(object({key = string, value = string, effect = string}))` | A list of taints to apply to the nodes in the node group. Each taint is an object with `key`, `value`, and `effect` attributes. |
| `labels` | `map(string)` | A map of labels to apply to the nodes in the node group. Each label is a key-value pair. |

# The Changes:
  - [Upgrade to 3.x.x](https://github.com/mrnim94/terraform-aws-eks-windows/blob/master/docs/UPGRADE-3.0.md)

# Issue Reference:
  - https://github.com/mrnim94/terraform-aws-eks-windows/blob/master/docs/Issue.md
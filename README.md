# terraform-aws-eks-windows

The eks windows module is based on the eks module v20.x.x

I want to provide the easy ways for you to install the eks windows

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

## Extra node for special cases   

Arcording Issuse: https://github.com/mrnim94/terraform-aws-eks-windows/issues/11   
Suppose you create the individual node group for a particular purpose such as "storage, mesh controller" and don't want them to affect the product application. In that case, you will need to configure the extra node group.   


```hcl
####...

module "eks-windows" {
  source  = "mrnim94/eks-windows/aws"
  version = "2.5.1"
  ####....
  ######....

  ### For extra Node Group
  extra_node_group = true
  extra_desired_size = 1
  extra_max_size = 1
  extra_min_size = 1
  extra_instance_type = "m5.2xlarge"
  extra_node_taints = [
    {
      key    = "key1"
      value  = "true"
      effect = "NO_SCHEDULE" # effect is required. Valid effect value = [NO_SCHEDULE, NO_EXECUTE, PREFER_NO_SCHEDULE]
    },
    {
      key    = "key2"
      value  = "true"
      effect = "PREFER_NO_SCHEDULE"
    }
  ]
  extra_node_labels = {
    "key1" : "value1"
    "key2" : "value2"
  }

}
```

### Assign the specific subnet ids for Extra node  
Arcording Issuse: https://github.com/mrnim94/terraform-aws-eks-windows/issues/29     

If you only want the EC2 of the Extra node which is created on the specific subnet, you will need to use **extra_subnet_ids** variable.   
First, you need to get the subnet IDs of the existing VPCs that belong to availability zones.

```hcl
data "aws_subnets" "eu_central_1b" {
  filter {
    name   = "vpc-id"
    values = [data.terraform_remote_state.network.outputs.vpc_id]
  }

  filter {
    name   = "availability-zone"
    values = ["eu-central-1b"]
  }
}
```

Next, transfer IDs at data "aws_subnets" to "extra_subnet_ids" variable.   

```hcl
module "eks-windows" {
  source  = "mrnim94/eks-windows/aws"
  version = "2.5.1"
  ####....
  ######....

  ### For extra Node Group
  extra_node_group = true
  extra_desired_size = 1
  extra_max_size = 1
  extra_min_size = 1
  extra_instance_type = "m5.2xlarge"
  extra_node_taints = [
    {
      key    = "key1"
      value  = "true"
      effect = "NO_SCHEDULE" # effect is required. Valid effect value = [NO_SCHEDULE, NO_EXECUTE, PREFER_NO_SCHEDULE]
    },
    {
      key    = "key2"
      value  = "true"
      effect = "PREFER_NO_SCHEDULE"
    }
  ]
  extra_node_labels = {
    "key1" : "value1"
    "key2" : "value2"
  }
  extra_subnet_ids = data.aws_subnets.eu_central_1b.ids
}
```
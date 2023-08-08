# terraform-aws-eks-windows

The eks windows module is based on the eks module v19.x.x

I want to provide the easy ways for you to install the eks windows

## Install EKS windows on vpc that is created by VPC Terrform Module.

### Create folder and file: yaml-templates/vpc-resource-controller-configmap.yaml

```hcl
apiVersion: v1
kind: ConfigMap
metadata:
  name: amazon-vpc-cni
  namespace: kube-system
data:
  enable-windows-ipam: "true"
```

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
    version = "2.0.0"
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

## Extra node for special cases   

Arcording Issuse: https://github.com/mrnim94/terraform-aws-eks-windows/issues/11   
Suppose you create the individual node group for a particular purpose such as "storage, mesh controller" and don't want them to affect the product application. In that case, you will need to configure the extra node group.   


```hcl
####...

module "eks-windows" {
  source  = "mrnim94/eks-windows/aws"
  version = "2.0.0"
  ####....
  ######....

  ### For extra Node Group
  extra_node_group = true
  extra_desired_size = 1
  extra_max_size = 1
  extra_min_size = 1
  extra_instance_type = "m5.2xlarge"
	node_taints = "test=true:NoSchedule"
	node_labels = "key1=value1,key2=value2"
}
```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.13.0"
    }
  }
}
provider "aws" {
  region = var.region
}
data "aws_caller_identity" "current" {}
locals {
    account_id = data.aws_caller_identity.current.account_id
}
#### Nodegroups - Images

data "aws_ami" "lin_ami" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amazon-eks-node-${var.eks_cluster_version}-*"]
    }
}
data "aws_ami" "win_ami" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["Windows_Server-2019-English-Core-EKS_Optimized-${var.eks_cluster_version}-*"]
    }
}

resource "aws_kms_key" "eks" {
  description = "EKS Encryption Key"
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  version = "~> 19.15"
  vpc_id = var.vpc_id
  cluster_name = var.eks_cluster_name
  subnet_ids = var.private_subnet_ids
  cluster_enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_endpoint_private_access = true #true
  cluster_endpoint_public_access  = true #false
  cluster_version                 = var.eks_cluster_version
  cluster_encryption_config = {
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }
  ### Allow SSM access for Nodes
  self_managed_node_group_defaults = {
    update_launch_template_default_version = true
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
    
    ### https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/examples/self_managed_node_group/main.tf#L66-L72
    ## enable discovery of autoscaling groups by cluster-autoscaler
    autoscaling_group_tags = {
      "k8s.io/cluster-autoscaler/enabled" : true,
      "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" : "owned",
    }
  }
  tags = {
    Name = "${var.eks_cluster_name}"
  }
  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    # egress_all = {
    #   description      = "Node all egress"
    #   protocol         = "-1"
    #   from_port        = 0
    #   to_port          = 0
    #   type             = "egress"
    #   cidr_blocks      = ["0.0.0.0/0"]
    #   ipv6_cidr_blocks = ["::/0"]
    # }

    #     ## Security Group for Metrics Server
    # ingress_cluster_metricserver = {
    #   description                   = "Cluster to node 4443 (Metrics Server)"
    #   protocol                      = "tcp"
    #   from_port                     = 4443
    #   to_port                       = 4443
    #   type                          = "ingress"
    #   source_cluster_security_group = true 
    # }
    # #https://github.com/kubernetes-sigs/metrics-server/issues/448
  }

  self_managed_node_groups = merge(
    {
      linux = {
        platform = "linux"
        name = "linux"
        public_ip    = false
        instance_type = var.lin_instance_type
        key_name = var.node_host_key_name
        desired_size = var.lin_desired_size
        max_size = var.lin_max_size
        min_size = var.lin_min_size
        ami_id = data.aws_ami.lin_ami.id
        #####################
        #### BOOTSTRAPING ###
        #####################
        bootstrap_extra_args = chomp(
        <<-EOT
        --kubelet-extra-args '--max-pods=${var.max_ips_per_node} --node-labels=apps=true'
        EOT
        )


        ebs_optimized     = true
        block_device_mappings = {
          xvda = {
            device_name = "/dev/xvda"
            ebs = {
              volume_size           = 100
              volume_type           = "gp3"
              iops                  = 3000
              throughput            = 125
              encrypted             = true
              delete_on_termination = true
            }
          }
        }
      }
      windows = {
        platform = "windows"
        name = "windows"
        public_ip    = false
        instance_type = var.win_instance_type
        key_name = var.node_host_key_name
        desired_size = var.win_desired_size
        max_size = var.win_max_size
        min_size = var.win_min_size
        ami_id = data.aws_ami.win_ami.id
        #####################
        #### BOOTSTRAPING ###
        #####################
        bootstrap_extra_args = chomp(
        <<-EOT
        -KubeletExtraArgs '--max-pods=${var.max_ips_per_node} --node-labels=apps=true'
        EOT
        )

        ebs_optimized     = true
        block_device_mappings = {
          xvda = {
            device_name = "/dev/xvda"
            ebs = {
              volume_size           = 100
              volume_type           = "gp3"
              iops                  = 3000
              throughput            = 125
              encrypted             = true
              delete_on_termination = true
            }
          }
        }
      }
    },

    var.extra_node_group ? {
      extra = {
        count = var.extra_node_group ? 1 : 0
        platform = "linux"
        name = "extra"
        public_ip    = false
        instance_type = var.extra_instance_type
        key_name = var.node_host_key_name
        desired_size = var.extra_desired_size
        max_size = var.extra_max_size
        min_size = var.extra_min_size
        ami_id = data.aws_ami.lin_ami.id
        bootstrap_extra_args = chomp(
          <<-EOT
          --kubelet-extra-args '--max-pods=${var.max_ips_per_node} --node-labels=${var.node_labels} --register-with-taints=${var.node_taints}'
          EOT
        )

        ebs_optimized     = true
        block_device_mappings = {
          xvda = {
            device_name = "/dev/xvda"
            ebs = {
              volume_size           = 100
              volume_type           = "gp3"
              iops                  = 3000
              throughput            = 125
              encrypted             = true
              delete_on_termination = true
            }
          }
        }
      }
    } : {}
  ) ## end merge function 

  cluster_addons = {
    vpc-cni = {
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }
}

### Prerequisites for Windows Node enablement
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

locals {
  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters = [{
      name = module.eks.cluster_name
      cluster = {
        certificate-authority-data = module.eks.cluster_certificate_authority_data
        server                     = module.eks.cluster_endpoint
      }
    }]
    contexts = [{
      name = "terraform"
      context = {
        cluster = module.eks.cluster_name
        user    = "terraform"
      }
    }]
    users = [{
      name = "terraform"
      user = {
        token = data.aws_eks_cluster_auth.this.token
      }
    }]
  })
}


### Apply changes to aws_auth
### Windows node Cluster enablement:  https://docs.aws.amazon.com/eks/latest/userguide/windows-support.html
resource "null_resource" "apply" {
  triggers = {
    kubeconfig = base64encode(local.kubeconfig)
    cmd_patch  = <<-EOT
      kubectl create configmap aws-auth -n kube-system --kubeconfig <(echo $KUBECONFIG | base64 --decode)
      kubectl patch configmap/aws-auth --patch "${module.eks.aws_auth_configmap_yaml}" -n kube-system --kubeconfig <(echo $KUBECONFIG | base64 --decode)
      kubectl get cm aws-auth -n kube-system -o json --kubeconfig <(echo $KUBECONFIG | base64 --decode) | jq --arg add "`cat yaml-templates/additional_roles_aws_auth.yaml`" '.data.mapRoles += $add' | kubectl apply --kubeconfig <(echo $KUBECONFIG | base64 --decode) -f -
      kubectl apply --kubeconfig <(echo $KUBECONFIG | base64 --decode) -f yaml-templates/vpc-resource-controller-configmap.yaml
    EOT
  }
    provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = self.triggers.kubeconfig
    }
    command = self.triggers.cmd_patch
  }
}

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix      = "${var.eks_cluster_name}-vpc-cni"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = {
    Name = "${var.eks_cluster_name}"
  }
}
# data "aws_ami" "win_ami" {
#   most_recent = true
#   owners      = ["amazon"]
#   filter {
#     name   = "name"
#     values = ["Windows_Server-2019-English-Core-EKS_Optimized-${var.eks_cluster_version}-*"]
#   }
# }

# Fetch CIDR blocks for each subnet ID
data "aws_subnet" "subnets" {
  for_each = toset(concat(var.private_subnet_ids, var.public_subnet_ids))

  id = each.value
}

module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "20.8.3"
  cluster_name                   = var.eks_cluster_name
  cluster_version                = var.eks_cluster_version
  subnet_ids                     = concat(var.private_subnet_ids, var.public_subnet_ids)
  vpc_id                         = var.vpc_id
  cluster_endpoint_public_access = true

  node_security_group_additional_rules = {
    ingress_subnet_ids_all = {
      description = "Node to node all ports/protocols in subnet IDs assigned to install EKS"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = [for s in data.aws_subnet.subnets : s.cidr_block]
    }
  }

  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = merge(
    {
      linux = {
        # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
        # so we need to disable it to use the default template provided by the AWS EKS managed node group service

        tags = {
          "k8s.io/cluster-autoscaler/enabled"                 = "true",
          "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
        }

        instance_types = [var.lin_instance_type]
        min_size       = var.lin_min_size
        max_size       = var.lin_max_size
        desired_size   = var.lin_desired_size
        key_name       = var.node_host_key_name

        ebs_optimized = true
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
        platform = "windows" # Custom AMI
        # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
        # so we need to disable it to use the default template provided by the AWS EKS managed node group service
        # use_custom_launch_template = true # Custom AMI
        ami_type = var.windows_ami_type #####
        # ami_id = data.aws_ami.win_ami.id

        tags = {
          "k8s.io/cluster-autoscaler/enabled"                 = "true",
          "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
        }
        instance_types = [var.win_instance_type]
        min_size       = var.win_min_size
        max_size       = var.win_max_size
        desired_size   = var.win_desired_size
        key_name       = var.node_host_key_name
        #   #####################
        #   #### BOOTSTRAPING ###
        #   #####################
        enable_bootstrap_user_data = true
        pre_bootstrap_user_data = (var.disable_windows_defender ? <<-EOT
        # Add Windows Defender exclusion 
        Set-MpPreference -DisableRealtimeMonitoring $true
        
        EOT
        : "")
        

        # bootstrap_extra_args = chomp(
        #   <<-EOT
        # -KubeletExtraArgs '--node-labels=apps=true'
        # EOT
        # )

        # post_bootstrap_user_data = var.disable_windows_defender ? chomp(
        #   <<-EOT
        #   # Add Windows Defender exclusion 
        #   Set-MpPreference -DisableRealtimeMonitoring $true

        #   EOT
        # ) : ""


        ebs_optimized = true
        block_device_mappings = [
          {
            device_name = "/dev/sda1"
            ebs = {
              volume_size           = 100
              volume_type           = "gp3"
              iops                  = 3000
              throughput            = 125
              encrypted             = true
              delete_on_termination = true
            }
          }
        ]
      }
    },

    var.extra_node_group ? {
      extra = {
        count         = var.extra_node_group ? 1 : 0
        instance_type = [var.extra_instance_type]
        key_name      = var.node_host_key_name
        desired_size  = var.extra_desired_size
        max_size      = var.extra_max_size
        min_size      = var.extra_min_size
        subnet_ids    = local.effective_win_subnet_ids
        taints        = var.extra_node_taints
        labels        = var.extra_node_labels
        #   #####################
        #   #### BOOTSTRAPING ###
        #   #####################
        # enable_bootstrap_user_data = true
        # bootstrap_extra_args = chomp(
        #   <<-EOT
        #   --kubelet-extra-args '--node-labels=${var.extra_node_labels} --register-with-taints=${var.extra_node_taints}'
        #   EOT
        # )

        ebs_optimized = true
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
  )
  cluster_addons = {
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
  }
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

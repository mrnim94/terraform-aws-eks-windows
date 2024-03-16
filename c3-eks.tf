data "aws_ami" "win_ami" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["Windows_Server-2019-English-Core-EKS_Optimized-${var.eks_cluster_version}-*"]
    }
}

module "eks" {
  source                         = "terraform-aws-modules/eks/aws"
  version                        = "20.2.1"
  cluster_name                   = var.eks_cluster_name
  cluster_version                = var.eks_cluster_version
  subnet_ids                     = concat(var.private_subnet_ids, var.public_subnet_ids)
  vpc_id                         = var.vpc_id
  cluster_endpoint_public_access = true

  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    linux = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false
      tags = {
        "k8s.io/cluster-autoscaler/enabled"                 = "true",
        "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
      }

      instance_types = [var.lin_instance_type]
      min_size       = var.lin_min_size
      max_size       = var.lin_max_size
      desired_size   = var.lin_desired_size
      key_name = var.node_host_key_name
    }
    windows = {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      # use_custom_launch_template = false
      ami_type                   = var.windows_ami_type
      # ami_id = data.aws_ami.win_ami.id
      tags = {
        "k8s.io/cluster-autoscaler/enabled"                 = "true",
        "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
      }
      instance_types = [var.win_instance_type]
      min_size       = var.win_min_size
      max_size       = var.win_max_size
      desired_size   = var.win_desired_size
      key_name = var.node_host_key_name
      #####################
      #### BOOTSTRAPING ###
      #####################
      enable_bootstrap_user_data = true

      post_bootstrap_user_data = var.disable_windows_defender ? chomp(<<-EOT
      # Add Windows Defender exclusion 
      Set-MpPreference -DisableRealtimeMonitoring $true

      EOT
      ) : ""
    }
  }
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
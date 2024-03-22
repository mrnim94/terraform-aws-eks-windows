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
  version                        = "20.8.3"
  cluster_name                   = var.eks_cluster_name
  cluster_version                = var.eks_cluster_version
  subnet_ids                     = concat(var.private_subnet_ids, var.public_subnet_ids)
  vpc_id                         = var.vpc_id
  cluster_endpoint_public_access = true

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = merge( {
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
      # platform = "windows" # Custom AMI
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false # NO Custom AMI
      ami_type = var.windows_ami_type
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

      enable_bootstrap_user_data = true
      post_bootstrap_user_data = (var.disable_windows_defender ? <<-EOT
      # Add Windows Defender exclusion 
      Set-MpPreference -DisableRealtimeMonitoring $true
      
      EOT
      : "")
    }
  }, // begin dynamic configurations
  { for ng in var.custom_node_groups : ng.name => {
      # By default, the module creates a launch template to ensure tags are propagated to instances, etc.,
      # so we need to disable it to use the default template provided by the AWS EKS managed node group service
      use_custom_launch_template = false
      tags = {
        "k8s.io/cluster-autoscaler/enabled"                 = "true",
        "k8s.io/cluster-autoscaler/${var.eks_cluster_name}" = "owned"
      }

      taints = [
        {
          key    = "test"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
      labels = {
        "deployment" : "smb"
      }

      instance_types = [ng.instance_type]
      min_size       = ng.min_size
      max_size       = ng.max_size
      desired_size   = ng.desired_size
      key_name = var.node_host_key_name
    }
  }
  ) //end Merge
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

  # the amazon-vpc-cni Configmap
  vpc_resource_controller_configmap_yaml = <<-EOT
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: amazon-vpc-cni
    namespace: kube-system
  data:
    enable-windows-ipam: "true"
  EOT
}

### Apply changes to aws_auth
### Windows node Cluster enablement:  https://docs.aws.amazon.com/eks/latest/userguide/windows-support.html
resource "null_resource" "apply" {
  depends_on = [module.eks]  # Ensuring this resource is applied after the EKS module is fully provisioned
  triggers = {
    kubeconfig = base64encode(local.kubeconfig)
    cmd_patch  = <<-EOT
      for i in {1..5}; do
        echo "$YAML_CONTENT" | kubectl apply --kubeconfig <(echo $KUBECONFIG | base64 --decode) -f - && break || sleep 10;
      done
    EOT
  }
    provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = self.triggers.kubeconfig
      YAML_CONTENT = local.vpc_resource_controller_configmap_yaml
    }
    command = self.triggers.cmd_patch
  }
}
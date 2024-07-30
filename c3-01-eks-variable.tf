variable "region" {
  description = "Please enter the region used to deploy this infrastructure"
  type        = string
}

variable "vpc_id" {
  type        = string
  description = "Id for the VPC for CTFd"
  default     = null
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet ids"
  default     = []
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet ids"
  default     = []
}

variable "eks_cluster_name" {
  type        = string
  description = "Name for the EKS cluster"
  default     = "eks"
}
variable "eks_cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster"
}

variable "lin_instance_type" {
  description = "Instance size for EKS linux worker nodes."
  default     = "m5.large"
  type        = string
}

# eks autoscaling
variable "lin_min_size" {
  description = "Minimum number of Linux nodes for the EKS."
  default     = 1
  type        = number
}

variable "lin_desired_size" {
  description = "Desired capacity for Linux nodes for the EKS."
  default     = 1
  type        = number
}

variable "lin_max_size" {
  description = "Minimum number of Linux nodes for the EKS."
  default     = 2
  type        = number
}


# # eks autoscaling for windows
variable "win_min_size" {
  description = "Minimum number of Windows nodes for the EKS"
  default     = 1
  type        = number
}

variable "win_desired_size" {
  description = "Desired capacity for Windows nodes for the EKS."
  default     = 1
  type        = number
}

variable "win_max_size" {
  description = "Maximum number of Windows nodes for the EKS."
  default     = 2
  type        = number
}

variable "win_instance_type" {
  description = "Instance size for EKS linux worker nodes."
  default     = "m5.large"
  type        = string
}

variable "windows_ami_type" {
  description = "AMI type for the Windows Nodes."
  type        = string
  default     = "WINDOWS_CORE_2019_x86_64"
}

variable "node_host_key_name" {
  description = "Please enter the name of the SSH key pair that should be assigned to the worker nodes of the cluster"
  type        = string
}

variable "disable_windows_defender" {
  description = "Flag to disable Windows Defender. Set to true to disable."
  type        = bool
  default     = false # Set the default as per your requirement
}

######################
## EXTRA NODE GROUP ##
# ######################
# variable "extra_node_group" {
#   description = "When you want to create a extra node group for the special purpose"
#   type        = bool
#   default     = false # Set to true to enable the extra_node_group, or false to disable it
# }

# variable "extra_instance_type" {
#   description = "Please enter the instance type to be used for the extra Linux worker nodes"
#   type        = string
#   default     = "m5.large"
# }
# variable "extra_min_size" {
#   description = "Please enter the minimal size for the extra Linux ASG"
#   type        = string
#   default     = "1"
# }
# variable "extra_max_size" {
#   description = "Please enter the maximal size for the extra Linux ASG"
#   type        = string
#   default     = "1"
# }

# variable "extra_desired_size" {
#   description = "Please enter the desired size for the extra Linux ASG"
#   type        = string
#   default     = "1"
# }

# variable "extra_node_labels" {
#   description = "Node labels for the EKS nodes"
#   type        = map(string)
#   default     = null
# }

# variable "extra_node_taints" {
#   description = "Taints for the EKS nodes"
#   type        = any
#   default     = {}
# }

# variable "extra_subnet_ids" {
#   description = "List of subnet IDs for Extra node group"
#   type        = list(string)
#   default     = []
# }

variable "custom_node_groups" {
  description = "List of custom node group configurations"
  type        = list(object({
    name          = string
    platform      = string
    windows_ami_type = optional(string, "WINDOWS_CORE_2019_x86_64")
    subnet_ids    = optional(list(string), [])
    instance_type = string
    desired_size  = number
    max_size      = number
    min_size      = number
    disable_windows_defender = optional(bool , false)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
    labels = map(string)
  }))
  default = []
}
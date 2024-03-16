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
  default = "WINDOWS_CORE_2019_x86_64"
}

variable "node_host_key_name" {
  description = "Please enter the name of the SSH key pair that should be assigned to the worker nodes of the cluster"
  type        = string
}

variable "disable_windows_defender" {
  description = "Flag to disable Windows Defender. Set to true to disable."
  type        = bool
  default     = false  # Set the default as per your requirement
}
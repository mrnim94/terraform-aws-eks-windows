variable "private_subnet_ids" {
  description = "Please enter a list of private subnet ids to be used"
  type        = any
}

# variable "public_subnet_ids" {
#   description = "Please enter a list of public subnet ids to be used"
#   type        = any
# }

variable "vpc_id" {
  description = "Please enter the ID of the VPC"
  type        = string
}
variable "region" {
  description = "Please enter the region used to deploy this infrastructure"
  type        = string
}
variable "eks_cluster_version" {
  description = "Please enter the EKS cluster version"
  type        = string
}
variable "eks_cluster_name" {
  description = "Please enter an EKS cluster name"
  type        = string
}
variable "lin_instance_type" {
  description = "Please enter the instance type to be used for the Linux worker nodes"
  type        = string
}
variable "lin_min_size" {
  description = "Please enter the minimal size for the Linux ASG"
  type        = string
}
variable "lin_max_size" {
  description = "Please enter the maximal size for the Linux ASG"
  type        = string
}
variable "lin_desired_size" {
  description = "Please enter the desired size for the Linux ASG"
  type        = string
}
variable "win_min_size" {
  description = "Please enter the minimal size for the Windows ASG"
  type        = string
}
variable "win_max_size" {
  description = "Please enter the maximal size for the Windows ASG"
  type        = string
}
variable "win_desired_size" {
  description = "Please enter the desired size for the Windows ASG"
  type        = string
}
variable "win_instance_type" {
  description = "Please enter the instance type to be used for the Windows worker nodes"
  type        = string
}
variable "node_host_key_name" {
  description = "Please enter the name of the SSH key pair that should be assigned to the worker nodes of the cluster"
  type        = string
}


variable "max_ips_per_node" {
  description = "Calculate the number of maximum pods per node, https://nimtechnology.com/2023/06/23/eks-ips-increase-most-many-ips-as-possible-on-each-node-of-your-eks/#2221_Adjust_kubelet"
  type        = string
  default = "110"
}
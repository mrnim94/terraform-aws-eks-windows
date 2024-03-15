# variable "private_subnet_ids" {
#   description = "Please enter a list of private subnet ids to be used"
#   type        = any
# }

# # variable "public_subnet_ids" {
# #   description = "Please enter a list of public subnet ids to be used"
# #   type        = any
# # }

# variable "vpc_id" {
#   description = "Please enter the ID of the VPC"
#   type        = string
# }
# variable "region" {
#   description = "Please enter the region used to deploy this infrastructure"
#   type        = string
# }
# variable "eks_cluster_version" {
#   description = "Please enter the EKS cluster version"
#   type        = string
# }
# variable "eks_cluster_name" {
#   description = "Please enter an EKS cluster name"
#   type        = string
# }
# variable "lin_instance_type" {
#   description = "Please enter the instance type to be used for the Linux worker nodes"
#   type        = string
# }
# variable "lin_min_size" {
#   description = "Please enter the minimal size for the Linux ASG"
#   type        = string
# }
# variable "lin_max_size" {
#   description = "Please enter the maximal size for the Linux ASG"
#   type        = string
# }
# variable "lin_desired_size" {
#   description = "Please enter the desired size for the Linux ASG"
#   type        = string
# }
# variable "win_min_size" {
#   description = "Please enter the minimal size for the Windows ASG"
#   type        = string
# }
# variable "win_max_size" {
#   description = "Please enter the maximal size for the Windows ASG"
#   type        = string
# }
# variable "win_desired_size" {
#   description = "Please enter the desired size for the Windows ASG"
#   type        = string
# }
# variable "win_instance_type" {
#   description = "Please enter the instance type to be used for the Windows worker nodes"
#   type        = string
# }
# variable "node_host_key_name" {
#   description = "Please enter the name of the SSH key pair that should be assigned to the worker nodes of the cluster"
#   type        = string
# }


# # variable "max_ips_per_node" {
# #   description = "Calculate the number of maximum pods per node, https://nimtechnology.com/2023/06/23/eks-ips-increase-most-many-ips-as-possible-on-each-node-of-your-eks/#2221_Adjust_kubelet"
# #   type        = string
# #   default = "110"
# # }

# ##### Extra node
# ################

# variable "extra_node_group" {
#   description = "When you want to create a extra node group for the special purpose"
#   type    = bool
#   default = false  # Set to true to enable the extra_node_group, or false to disable it
# }

# variable "extra_instance_type" {
#   description = "Please enter the instance type to be used for the extra Linux worker nodes"
#   type        = string
#   default = "t3.xlarge"
# }
# variable "extra_min_size" {
#   description = "Please enter the minimal size for the extra Linux ASG"
#   type        = string
#   default = "1"
# }
# variable "extra_max_size" {
#   description = "Please enter the maximal size for the extra Linux ASG"
#   type        = string
#   default = "1"
# }
# variable "extra_desired_size" {
#   description = "Please enter the desired size for the extra Linux ASG"
#   type        = string
#   default = "1"
# }

# variable "extra_subnet_ids" {
#  description = "List of subnet IDs for Extra node group"
#  type        = list(string)
#  default     = []
# }

# variable "extra_node_labels" {
#   description = "Node labels for the EKS nodes. Exp: `node_labels = key1=value1,key2=value2`"
#   type        = string
#   default     = ""
# }

# variable "extra_node_taints" {
#   description = "Taints for the EKS nodes, Exp: `node_taints = test=true:NoSchedule`"
#   type        = string
#   default     = ""
# }


# variable "disable_windows_defender" {
#   description = "Flag to disable Windows Defender. Set to true to disable."
#   type        = bool
#   default     = false  # Set the default as per your requirement
# }

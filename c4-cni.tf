# data "aws_eks_cluster" "cluster_windows" {
#   name = module.eks.cluster_name
#   depends_on = [
#     module.eks
#   ]
# }

# data "aws_eks_cluster_auth" "cluster_windows" {
#   name = module.eks.cluster_name
#   depends_on = [
#     module.eks
#   ]
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.cluster_windows.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster_windows.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.cluster_windows.token
#   // Ensure the version of the Kubernetes provider you are using does not require `load_config_file`.
# }

# # eks is spun up with aws-vpc-cni helm chart regardless if it is specified in cluster_addons
# # this config can't be set from terraform that I can see. The best option is to overwrite
# # # the existing configmap with the settings we need.
# resource "kubernetes_config_map_v1_data" "amazon_vpc_cni" {
#   metadata {
#     name      = "amazon-vpc-cni"
#     namespace = "kube-system"
#   }
#   data = {
#     enable-windows-ipam = true
#   }
#   force = true
#   depends_on = [
#     module.eks
#   ]
# }
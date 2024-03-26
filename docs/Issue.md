## Issues:

### Error when overwriting the `amazon_vpc_cni` config map.

```plaintext
Plan: 3 to add, 1 to change, 2 to destroy.
╷
│ Error: Get "http://localhost/api/v1/namespaces/kube-system/configmaps/amazon-vpc-cni": dial tcp [::1]:80: connect: connection refused
│ 
│   with module.eks-windows.kubernetes_config_map_v1_data.amazon_vpc_cni[0],
│   on .terraform/modules/eks-windows/c4-cni.tf line 25, in resource "kubernetes_config_map_v1_data" "amazon_vpc_cni":
│   25: resource "kubernetes_config_map_v1_data" "amazon_vpc_cni" {
│ 
╵
2024-03-26T08:30:40.15121401Z stdout P 
```

refer to the link: [**\[Terraform\] Resolving aws-auth error when deleting EKS Cluster**](https://kim-dragon.tistory.com/262)

We need manually to delete `amazon_vpc_cni` from `tfstate` by the below command:

```plaintext
terraform state rm module.eks-windows.kubernetes_config_map_v1_data.amazon_vpc_cni
```
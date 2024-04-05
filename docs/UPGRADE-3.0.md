## **Upgrade from v2.x.x to 3.x.x**

we decided to migrate the EKS node Group from the **self-managed node group** to the **managed node group**.

You can refer to [**\[EKS windows\] Using EKS terraform module to install K8S windows with manage node Group mode.**](https://nimtechnology.com/2024/03/25/eks-windows-using-eks-terraform-module-to-install-k8s-windows-with-manage-node-group-mode/) to understand something regarding installing the EKS windows with the manage node group.

### Variable and output changes

1.  Removed variables:
    *   extra\_node\_group
    *   extra\_desired\_size 
    *   extra\_max\_size
    *   extra\_min\_size
    *   extra\_instance\_type
    *   node\_taints
    *   node\_labels

# Define Local Values in Terraform
locals {
  effective_win_subnet_ids = length(var.extra_subnet_ids) > 0 ? var.extra_subnet_ids : var.private_subnet_ids
}

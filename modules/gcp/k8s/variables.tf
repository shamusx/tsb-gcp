variable "name_prefix" {
  description = "name prefix"
}

variable "cluster_name" {
  description = "cluster name"
}

variable "project_id" {
}

variable "region" {
}

variable "k8s_version" {
}

variable "output_path" {
}

variable "cert-manager_enabled" {
  default = true
}
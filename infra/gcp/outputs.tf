output "registry" {
  value = module.gcp_base.*.registry
}

output "public_ip" {
  value = module.gcp_jumpbox.*.public_ip
}

output "pkey" {
  value     = module.gcp_jumpbox.*.pkey
  sensitive = true
}

output "cluster_name" {
  value = module.gcp_k8s.*.cluster_name
}

output "host" {
  value     = module.gcp_k8s.*.host
  sensitive = true
}

output "cluster_ca_certificate" {
  value     = module.gcp_k8s.*.cluster_ca_certificate
  sensitive = true
}

output "token" {
  value     = module.gcp_k8s.*.token
  sensitive = true
}

output "locality_region" {
  value = var.gcp_k8s_region
}

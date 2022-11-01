data "terraform_remote_state" "gcp" {
  backend = "local"
  config = {
    path = "../../infra/gcp/terraform.tfstate"
  }
}

module "cert-manager" {
  source                     = "../../modules/addons/cert-manager"
  cluster_name               = data.terraform_remote_state.gcp.outputs.cluster_name["${var.cluster_id}"]
  k8s_host                   = data.terraform_remote_state.gcp.outputs.host["${var.cluster_id}"]
  k8s_cluster_ca_certificate = data.terraform_remote_state.gcp.outputs.cluster_ca_certificate["${var.cluster_id}"]
  k8s_client_token           = data.terraform_remote_state.gcp.outputs.token["${var.cluster_id}"]
  cert-manager_enabled       = var.cert-manager_enabled
}

module "es" {
  source                     = "../../modules/addons/elastic"
  cluster_name               = data.terraform_remote_state.gcp.outputs.cluster_name["${var.cluster_id}"]
  k8s_host                   = data.terraform_remote_state.gcp.outputs.host["${var.cluster_id}"]
  k8s_cluster_ca_certificate = data.terraform_remote_state.gcp.outputs.cluster_ca_certificate["${var.cluster_id}"]
  k8s_client_token           = data.terraform_remote_state.gcp.outputs.token["${var.cluster_id}"]
}

module "tsb_mp" {
  source                     = "../../modules/tsb/mp"
  name_prefix                = var.name_prefix
  tsb_version                = var.tsb.version
  tsb_helm_repository        = var.tsb_helm_repository
  tsb_helm_version           = var.tsb.version
  tsb_fqdn                   = "${var.name_prefix}${var.student_count_index}.${var.domain}"
  tsb_org                    = var.tsb.org
  tsb_username               = var.tsb_username
  tsb_password               = var.tsb.password
  tsb_image_sync_username    = var.tsb.image_sync_username
  tsb_image_sync_apikey      = var.tsb.image_sync_apikey
  es_host                    = module.es.es_ip != "" ? module.es.es_ip : module.es.es_hostname
  es_username                = module.es.es_username
  es_password                = module.es.es_password
  es_cacert                  = module.es.es_cacert
  registry                   = data.terraform_remote_state.gcp.outputs.registry["${var.student_count_index}"]
  cluster_name               = data.terraform_remote_state.gcp.outputs.cluster_name["${var.cluster_id}"]
  k8s_host                   = data.terraform_remote_state.gcp.outputs.host["${var.cluster_id}"]
  k8s_cluster_ca_certificate = data.terraform_remote_state.gcp.outputs.cluster_ca_certificate["${var.cluster_id}"]
  k8s_client_token           = data.terraform_remote_state.gcp.outputs.token["${var.cluster_id}"]

}

module "gcp_register_fqdn" {
  source   = "../../modules/gcp/register_fqdn"
  dns_zone = "gcp.cx.tetrate.info"
  fqdn     = "${var.name_prefix}${var.student_count_index}.${var.domain}"
  address  = module.tsb_mp.ingress_ip != "" ? module.tsb_mp.ingress_ip : module.tsb_mp.ingress_hostname
}

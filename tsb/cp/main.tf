data "terraform_remote_state" "gcp" {
  backend = "local"
  config = {
    path = "../../infra/gcp/terraform.tfstate"
  }
}

data "terraform_remote_state" "tsb_mp" {
  backend = "local"
  config = {
    path = "../mp/terraform.tfstate.d/student_${var.student_count_index}/terraform.tfstate"
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

module "tsb_cp" {
  source                     = "../../modules/tsb/cp"
  cloud                      = "gcp"
  locality_region            = var.gcp_region
  cluster_id                 = var.cluster_id
  name_prefix                = "${var.name_prefix}-${var.cluster_id}"
  tsb_version                = var.tsb.version
  tsb_helm_repository        = var.tsb_helm_repository
  tsb_helm_version           = var.tsb.version
  tsb_mp_host                = "${var.name_prefix}${var.student_count_index}.${var.domain}"
  tier1_cluster              = false
  tsb_fqdn                   = "${var.name_prefix}${var.student_count_index}.${var.domain}"
  tsb_org                    = var.tsb.org
  tsb_username               = var.tsb_username
  tsb_password               = var.tsb.password
  tsb_cacert                 = data.terraform_remote_state.tsb_mp.outputs.tsb_cacert
  istiod_cacerts_tls_crt     = data.terraform_remote_state.tsb_mp.outputs.istiod_cacerts_tls_crt
  istiod_cacerts_tls_key     = data.terraform_remote_state.tsb_mp.outputs.istiod_cacerts_tls_key
  tsb_image_sync_username    = var.tsb.image_sync_username
  tsb_image_sync_apikey      = var.tsb.image_sync_apikey
  output_path                = var.output_path
  es_host                    = data.terraform_remote_state.tsb_mp.outputs.es_ip != "" ? data.terraform_remote_state.tsb_mp.outputs.es_ip : data.terraform_remote_state.tsb_mp.outputs.es_hostname
  es_username                = data.terraform_remote_state.tsb_mp.outputs.es_username
  es_password                = data.terraform_remote_state.tsb_mp.outputs.es_password
  es_cacert                  = data.terraform_remote_state.tsb_mp.outputs.es_cacert
  jumpbox_host               = data.terraform_remote_state.gcp.outputs.public_ip["${var.student_count_index}"]
  jumpbox_username           = var.jumpbox_username
  jumpbox_pkey               = data.terraform_remote_state.gcp.outputs.pkey["${var.student_count_index}"]
  registry                   = data.terraform_remote_state.gcp.outputs.registry["${var.student_count_index}"]
  cluster_name               = data.terraform_remote_state.gcp.outputs.cluster_name["${var.cluster_id}"]
  k8s_host                   = data.terraform_remote_state.gcp.outputs.host["${var.cluster_id}"]
  k8s_cluster_ca_certificate = data.terraform_remote_state.gcp.outputs.cluster_ca_certificate["${var.cluster_id}"]
  k8s_client_token           = data.terraform_remote_state.gcp.outputs.token["${var.cluster_id}"]
}

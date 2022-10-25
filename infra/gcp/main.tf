resource "random_string" "random_prefix" {
  length  = 4
  special = false
  lower   = true
  upper   = false
  numeric = false
}

resource "google_project" "tsb" {
  count           = var.student.count
  name            = "${var.name_prefix}-${random_string.random_prefix.result}-${count.index + 1}"
  project_id      = "${var.name_prefix}-${random_string.random_prefix.result}-${count.index + 1}"
  org_id          = var.gcp_org_id
  billing_account = var.gcp_billing_id
}

module "gcp_base" {
  source      = "../../modules/gcp/base"
  count       = var.student.count
  name_prefix = "${var.name_prefix}-${count.index + 1}"
  project_id  = "${var.name_prefix}-${random_string.random_prefix.result}-${count.index + 1}"
  region      = var.gcp_region
  org_id      = var.gcp_org_id
  billing_id  = var.gcp_billing_id
  cidr        = cidrsubnet(var.cidr, 4, 8 + count.index)
  depends_on = [
    google_project.tsb
  ]
}

module "gcp_jumpbox" {
  source                  = "../../modules/gcp/jumpbox"
  count                   = var.student.count
  name_prefix             = "${var.name_prefix}-${count.index + 1}"
  region                  = var.gcp_region
  project_id              = "${var.name_prefix}-${random_string.random_prefix.result}-${count.index + 1}"
  vpc_id                  = module.gcp_base["${count.index}"].vpc_id
  vpc_subnet              = module.gcp_base["${count.index}"].vpc_subnets[0]
  tsb_version             = var.tsb.version
  jumpbox_username        = var.jumpbox_username
  tsb_image_sync_username = var.tsb.image_sync_username
  tsb_image_sync_apikey   = var.tsb.image_sync_apikey
  registry                = module.gcp_base["${count.index}"].registry
  output_path             = var.output_path
}

module "gcp_k8s" {
  source       = "../../modules/gcp/k8s"
  count        = var.student.count * var.student.clusters
  name_prefix  = "tsbmp-${var.name_prefix}-${count.index % var.student.clusters + 1}"
  cluster_name = "tsbmp-${var.name_prefix}-${random_string.random_prefix.result}-${floor(count.index % var.student.clusters + 1)}"
  project_id   = "${var.name_prefix}-${random_string.random_prefix.result}-${floor(count.index / var.student.clusters + 1)}"
  region       = var.gcp_region
  k8s_version  = var.gcp_gke_k8s_version
  output_path  = var.output_path
  depends_on   = [module.gcp_jumpbox[0]]
}

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.gcp.outputs.host["${var.cluster_id}"]
  cluster_ca_certificate = base64decode(data.terraform_remote_state.gcp.outputs.cluster_ca_certificate["${var.cluster_id}"])
  token                  = data.terraform_remote_state.gcp.outputs.token["${var.cluster_id}"]
}

provider "helm" {
  kubernetes {
  host                   = data.terraform_remote_state.gcp.outputs.host["${var.cluster_id}"]
  cluster_ca_certificate = base64decode(data.terraform_remote_state.gcp.outputs.cluster_ca_certificate["${var.cluster_id}"])
  token                  = data.terraform_remote_state.gcp.outputs.token["${var.cluster_id}"]
  }
}

provider "kubectl" {
  host                   = data.terraform_remote_state.gcp.outputs.host["${var.cluster_id}"]
  cluster_ca_certificate = base64decode(data.terraform_remote_state.gcp.outputs.cluster_ca_certificate["${var.cluster_id}"])
  token                  = data.terraform_remote_state.gcp.outputs.token["${var.cluster_id}"]
  load_config_file       = false
}

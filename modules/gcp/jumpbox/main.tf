data "google_compute_subnetwork" "wait_for_compute_apis_to_be_ready" {
  self_link = var.vpc_subnet
  project   = var.project_id
  region    = var.region
}

data "google_compute_zones" "available" {
  project = var.project_id
  region  = data.google_compute_subnetwork.wait_for_compute_apis_to_be_ready.region
}

resource "tls_private_key" "generated" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "google_compute_default_service_account" "default" {
  project = var.project_id
  depends_on = [
    data.google_compute_subnetwork.wait_for_compute_apis_to_be_ready
  ]
}

resource "google_compute_instance" "jumpbox" {
  project      = var.project_id
  name         = "${var.name_prefix}-jumpbox"
  machine_type = "n1-standard-2"
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-minimal-2204-lts"
    }
  }

  network_interface {
    network    = var.vpc_id
    subnetwork = var.vpc_subnet
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    user-data = templatefile("${path.module}/jumpbox.userdata", {
      jumpbox_username        = var.jumpbox_username
      tsb_version             = var.tsb_version
      tsb_image_sync_username = var.tsb_image_sync_username
      tsb_image_sync_apikey   = var.tsb_image_sync_apikey
      docker_login            = "gcloud auth configure-docker -q"
      registry                = var.registry
      pubkey                  = tls_private_key.generated.public_key_openssh
    })
  }

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["cloud-platform"]
  }
}

resource "local_file" "tsbadmin_pem" {
  content         = tls_private_key.generated.private_key_pem
  filename        = "${var.output_path}/${var.name_prefix}-gcp-${var.jumpbox_username}.pem"
  depends_on      = [tls_private_key.generated]
  file_permission = "0600"
}

resource "local_file" "ssh_jumpbox" {
  content         = "ssh -i ${var.name_prefix}-gcp-${var.jumpbox_username}.pem -l ${var.jumpbox_username} ${google_compute_instance.jumpbox.network_interface[0].access_config[0].nat_ip}"
  filename        = "${var.output_path}/ssh-to-gcp-${var.name_prefix}-jumpbox.sh"
  file_permission = "0755"
}
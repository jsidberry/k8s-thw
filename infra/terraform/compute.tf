resource "google_project_service" "compute" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

locals {
  boot_image = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
  workers    = ["node-0", "node-1"]
}

resource "google_compute_instance" "jumpbox" {
  name         = "jumpbox"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["jumpbox"]
  labels       = { app = "k8s-thw" }

  metadata = {
    ssh-keys                 = local.ssh_keys_metadata
    internal-ssh-private-key = tls_private_key.ops.private_key_openssh
    internal-ssh-config      = local.internal_ssh_config
  }
  metadata_startup_script = local.jumpbox_startup_script

  boot_disk {
    initialize_params {
      image = local.boot_image
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.k8s_thw.id
    access_config {}
  }

  depends_on = [google_project_service.compute]
}

resource "google_compute_instance" "server" {
  name         = "server"
  machine_type = "e2-small"
  zone         = var.zone
  labels       = { app = "k8s-thw" }

  metadata = {
    ssh-keys = local.ssh_keys_metadata
  }

  boot_disk {
    initialize_params {
      image = local.boot_image
      size  = 20
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.k8s_thw.id
  }

  depends_on = [google_project_service.compute]
}

resource "google_compute_instance" "workers" {
  for_each     = toset(local.workers)
  name         = each.value
  machine_type = "e2-small"
  zone         = var.zone
  labels       = { app = "k8s-thw" }

  metadata = {
    ssh-keys = local.ssh_keys_metadata
  }

  boot_disk {
    initialize_params {
      image = local.boot_image
      size  = 20
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.k8s_thw.id
  }

  depends_on = [google_project_service.compute]
}

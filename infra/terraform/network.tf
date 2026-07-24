resource "google_compute_network" "k8s_thw" {
  name                    = "k8s-thw"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.compute]
}

resource "google_compute_subnetwork" "k8s_thw" {
  name          = "k8s-thw"
  network       = google_compute_network.k8s_thw.id
  ip_cidr_range = "10.240.0.0/24"
  region        = var.region
}

resource "google_compute_firewall" "allow_internal" {
  name    = "k8s-thw-allow-internal"
  network = google_compute_network.k8s_thw.name

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.240.0.0/24"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "k8s-thw-allow-ssh"
  network = google_compute_network.k8s_thw.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["jumpbox"]
}

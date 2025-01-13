terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  #credentials = file(var.credentials_file)
  project = var.project
  region  = var.region
}


resource "google_compute_network" "qdb-vpc" {
  name                                      = "qdb-vpc"
  routing_mode                              = "REGIONAL"
  auto_create_subnetworks                   = false
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
}

resource "google_compute_subnetwork" "qdb-subnet-with-logging" {
  name          = "qdb-subnet-with-logging"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.qdb-vpc.id
  stack_type    = "IPV4_ONLY"

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_route" "qdb-public-route" {
  name             = "qdb-public-route"
  network          = google_compute_network.qdb-vpc.id
  dest_range       = "0.0.0.0/0" # Destination IP range
  priority         = 1000
  next_hop_gateway = "default-internet-gateway" # Specify the next hop
}


resource "google_compute_firewall" "qdb-firewall" {
  name        = "qdb-firewall"
  description = "Creates firewall rule targeting tagged instances"
  network     = google_compute_network.qdb-vpc.id

  allow {
    protocol = "all"
  }

  source_ranges = [var.my_ip]

  target_tags = ["qdb"]
}


resource "google_compute_instance" "qdb-ubuntu" {
  name         = "qdb-ubuntu"
  machine_type = "n2d-standard-2"
  zone         = "australia-southeast1-a"

  tags = ["qdb"]

  boot_disk {
    initialize_params {
      image = "ubuntu-2410-oracular-amd64-v20241021"
      size  = 10
      type  = "pd-balanced"
    }
    auto_delete = true
  }

  attached_disk {
    source      = google_compute_disk.persistent-data.id
    device_name = google_compute_disk.persistent-data.name
  }


  network_interface {
    network    = google_compute_network.qdb-vpc.id
    subnetwork = google_compute_subnetwork.qdb-subnet-with-logging.id
    access_config {
      network_tier = "STANDARD"
    }

  }
}

output "public-ipv4" {
  value = google_compute_instance.qdb-ubuntu.network_interface.0.access_config.0.nat_ip
}


resource "google_compute_disk" "persistent-data" {
  name = "persistent-data"
  type = "pd-balanced"
  zone = "australia-southeast1-a"
  size = "20"
}


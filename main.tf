provider "google" {
  credentials = file("project-2-297319-918b48a4ad3f.json")
  project     = "project-2-297319"
  region      = "us-central1"
  zone        = "us-central1-a"
  user_project_override = true
}

resource "google_compute_instance_template" "my_lamp_instance" {
  name           = "my-instance-template"
  machine_type   = "e2-medium"
  can_ip_forward = false
  tags = ["foo", "bar"]

  disk {
    source_image = "ubuntu-2004-focal-v20201014"
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

resource "google_compute_target_pool" "my_target_pool" {
  name = "my-target-pool-2"
}

resource "google_compute_instance_group_manager" "my_group" {
  name = "my-igm"
  zone = "us-central1-a"

  version {
    instance_template  = google_compute_instance_template.my_lamp_instance.id
    name               = "primary"
  }

  target_pools       = [google_compute_target_pool.my_target_pool.id]
  base_instance_name = "lamp"
}

resource "google_compute_network" "vpc_network" {
  name                    = "terraform-vpc-145"
  auto_create_subnetworks = "true"
}

resource "google_compute_firewall" "my_firewall" {
  name    = "terraformfirewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = [80, 22]
  }
}

module "gce-lb-fr" {
  source       = "github.com/GoogleCloudPlatform/terraform-google-lb"
  region       = "us-central1"
  name         = "group1-lb"
  service_port = "80"
  target_tags  = ["allow-lb-service"]
}


resource "google_compute_autoscaler" "autoscal" {
  name   = "my-autoscaler"
  zone   = "us-central1-a"
  target = google_compute_instance_group_manager.my_group.id

  autoscaling_policy {
    max_replicas    = 4
    min_replicas    = 2
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

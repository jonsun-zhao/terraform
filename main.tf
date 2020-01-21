variable "tf_credentials" {}
variable "tf_project_id" {}

provider "google" {
  credentials = file(var.tf_credentials)

  project = var.tf_project_id
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "ci-cd-vpc"
    subnetwork = "us-central1"
    access_config {
    }
  }
}

resource "google_compute_instance_template" "k8s-master-template" {
  name        = "k8s-master-template"
  description = "This template is used to k8s template."

  tags = ["k8s", "master"]

  labels = {
    environment = "dev"
  }

  instance_description = "description assigned to instances"
  machine_type         = "n1-standard-1"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = "cos-cloud/cos-stable"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "ci-cd-vpc"
    subnetwork = "us-central1"
  }

  metadata = {
    k8s = "master"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

data "google_compute_image" "my_image" {
  family  = "debian-9"
  project = "debian-cloud"
}

resource "google_compute_instance_group_manager" "k8s-master" {
  name               = "k8s-master-igm"
  base_instance_name = "k8s-master"
  zone               = "us-central1-c"
  target_size        = "1"
  version {
    name              = "k8s-master"
    instance_template  = google_compute_instance_template.k8s-master-template.self_link
  }
}

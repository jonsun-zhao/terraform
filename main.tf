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


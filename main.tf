variable "tf_credentials" {}
variable "tf_project_id" {}
variable "gce_ssh_user" {}
variable "gce_ssh_pub_key" {}
variable "node_count" {
  default = "2"
}
variable "master_count" {
  default = "1"
}

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

resource "google_compute_instance_template" "k8s-master-template-2" {
  name        = "k8s-master-template-2"
  description = "This template is used to k8s template, with ssh key build in."

  tags = ["k8s", "master"]

  labels = {
    environment = "dev"
  }

  instance_description = "description assigned to instances"
  machine_type         = "n1-standard-4"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = "debian-cloud/debian-9"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "ci-cd-vpc"
    subnetwork = "us-central1"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = {
    k8s = "master"
    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key)}"
  }

  service_account {
    scopes = ["userinfo-email", "compute-ro", "storage-ro"]
  }
}

resource "google_compute_instance_template" "k8s-node-template" {
  name        = "k8s-node-template"
  description = "This template is used to k8s template, with ssh key build in."

  tags = ["k8s", "node"]

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
    source_image = "debian-cloud/debian-9"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "ci-cd-vpc"
    subnetwork = "us-central1"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = {
    k8s = "node"
    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key)}"
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
    instance_template  = google_compute_instance_template.k8s-master-template-2.self_link
  }
}


resource "google_compute_instance_group_manager" "k8s-node" {
  name               = "k8s-node-igm"
  base_instance_name = "k8s-node"
  zone               = "us-central1-c"
  target_size        = "2"
  version {
    name              = "k8s-node"
    instance_template  = google_compute_instance_template.k8s-node-template.self_link
  }
}


data "google_compute_instance_group" "k8s-master-igm" {
  name = "k8s-master"
}

data "google_compute_instance_group" "k8s-node-igm" { 
  
}

data "google_compute_instance" "k8s-master.instances" {
  name = "k8s-master-i"
}

output master-instances {
  value = "${data.google_compute_instance_group.k8s-master-igm.instances}"
}

data "google_compute_instances" "master-instances" {
  name = "master-instances-i"
}

output "k8s-master-internal-ip" {
  value = "${data.google_compute_instance.master-instances.network_interface.0.network_ip}"
}

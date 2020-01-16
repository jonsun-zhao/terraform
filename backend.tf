terraform {
 backend "gcs" {
   bucket  = "kubernetes-repro"
   prefix  = "terraform/state"
 }
}

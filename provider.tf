terraform {
  required_version = ">=1.0.0"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = ">=4.31.0"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = ">=4.31.0"
    }
  }
}

# Provider
provider "google" {    
  project = var.project_id
}
provider "google-beta" { 
  project = var.project_id
}

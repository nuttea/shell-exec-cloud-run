variable "project_id" {
  type    = string
}

variable "region" {
  type    = string
  default = "asia-southeast1"
}

variable "cloudrun_name" {
  type    = string
  default = "cloud-run-exec"
}

variable "report_bucket_path" {
  type    = string
  default = "reports/"
}
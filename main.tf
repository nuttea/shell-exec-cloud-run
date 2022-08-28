# [START google project enable required service apis]
resource "google_project_service" "run_api" {
  project                    = var.project_id
  service                    = "run.googleapis.com"
  disable_on_destroy         = false
}

resource "google_project_service" "iam_api" {
  project                    = var.project_id
  service                    = "iam.googleapis.com"
  disable_on_destroy         = false
}

resource "google_project_service" "resource_manager_api" {
  project                    = var.project_id
  service                    = "cloudresourcemanager.googleapis.com"
  disable_on_destroy         = false
}

resource "google_project_service" "scheduler_api" {
  project                    = var.project_id
  service                    = "cloudscheduler.googleapis.com"
  disable_on_destroy         = false
}
# [END google project enable required service apis]


# [START cloud storage report bucket]
resource "google_storage_bucket" "report_bucket" {
  project       = var.project_id
  name          = "${var.project_id}-cloudrun-report"
  location      = "ASIA-SOUTHEAST1"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
}
# [END cloud storage report bucket]

# [START cloudrun_service_sa]
resource "google_service_account" "cloudrun" {
  project      = var.project_id
  account_id   = "cloudrun-sa"
  description  = "Cloud Run Exec service account; used to run a report and upload to gcs"
  display_name = "cloudrun-sa"

  # Use an explicit depends_on clause to wait until API is enabled
  depends_on = [
    google_project_service.iam_api
  ]
}
# [END cloudrun_service_sa]

# [START cloudrun_service_account_iam]
resource "google_project_iam_member" "cloudrun" {
  project  = var.project_id
  member   = format("serviceAccount:%s", google_service_account.cloudrun.email)
  for_each = toset([
    "roles/monitoring.viewer",
    "roles/monitoring.metricWriter",
    "roles/logging.logWriter",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.objectViewer",
    "roles/artifactregistry.reader",
  ])
  role     = each.key
}

resource "google_storage_bucket_iam_member" "cloudrun_gcs_iam" {
  bucket = google_storage_bucket.report_bucket.name
  role = "roles/storage.admin"
  member = format("serviceAccount:%s", google_service_account.cloudrun.email)
}
# [END cloudrun_service_account_iam]

# [START cloudrun_service]
resource "google_cloud_run_service" "default" {
  project  = var.project_id
  name     = var.cloudrun_name
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.cloudrun.email
      timeout_seconds = 300
      container_concurrency = 80

      containers {
        image = "gcr.io/${var.project_id}/${var.cloudrun_name}"

        resources {
          limits = {
            cpu = "1000m"
            memory = "1Gi"
          }
        }
        
        env {
          name  = "BUCKET"
          value = google_storage_bucket.report_bucket.name
        }

        env {
          name  = "BUCKET_PATH"
          value = var.report_bucket_path
        }
      }

    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = 1
        "autoscaling.knative.dev/minScale" = 0
      }
      labels = {
        app : "cloud-run-exec"
        environment : "production"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  # Use an explicit depends_on clause to wait until API is enabled
  depends_on = [
    google_project_service.run_api,
    google_storage_bucket_iam_member.cloudrun_gcs_iam,
  ]
}
# [END cloudrun_service]

# [START cloudrun_service_scheduled_sa]
resource "google_service_account" "cloudrun-scheduler" {
  project      = var.project_id
  account_id   = "cloudrun-scheduler-sa"
  description  = "Cloud Scheduler service account; used to trigger scheduled Cloud Run jobs."
  display_name = "cloudrun-scheduler-sa"

  # Use an explicit depends_on clause to wait until API is enabled
  depends_on = [
    google_project_service.iam_api
  ]
}
# [END cloudrun_service_scheduled_sa]

# [START cloudrun_service_scheduled_iam]
resource "google_cloud_run_service_iam_member" "cloudrun-scheduler" {
  project = var.project_id
  location = google_cloud_run_service.default.location
  service = google_cloud_run_service.default.name
  role = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.cloudrun-scheduler.email}"
}
# [END cloudrun_service_scheduled_iam]

# [START cloudrun_service_scheduled_job]
resource "google_cloud_scheduler_job" "default" {
  name             = "scheduled-cloud-run-job"
  region         = var.region
  description      = "Invoke a Cloud Run container on a schedule."
  schedule         = "0 1 * * *"
  time_zone        = "Asia/Bangkok"
  attempt_deadline = "320s"

  retry_config {
    retry_count = 3
  }

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_service.default.status[0].url}/exec"
    body        = base64encode("/home/cloudsdk/run.sh")
    
    headers = {
      Content-Type = "text/plain",
    }

    oidc_token {
      service_account_email = google_service_account.cloudrun-scheduler.email
    }
  }

  # Use an explicit depends_on clause to wait until API is enabled
  depends_on = [
    google_project_service.scheduler_api
  ]
}
# [END cloudrun_service_scheduled_job]
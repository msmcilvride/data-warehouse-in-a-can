# Define provider
provider "google-beta" {
  # project     = "Data Warehouse in a Can"
  region      = var.region
}


# Create the project and assign a billing account
data "google_billing_account" "account" {
  display_name = var.billing_account_name
  open         = true
}

resource "google_project" "project" {
  name       = "Data Warehouse in a Can"
  project_id = "dwiac-0001"

  billing_account = data.google_billing_account.account.id
}


# Enable APIs
resource "google_project_service" "artifact_registry" {
  project = google_project.project.project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "bigquery" {
  project = google_project.project.project_id
  service = "bigquery.googleapis.com"
}

resource "google_project_service" "cloud_build" {
  project = google_project.project.project_id
  service = "cloudbuild.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloud_functions" {
  project = google_project.project.project_id
  service = "cloudfunctions.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloud_scheduler" {
  project = google_project.project.project_id
  service = "cloudscheduler.googleapis.com"

  disable_on_destroy = false
}


resource "google_project_service" "dataflow" {
  project = google_project.project.project_id
  service = "dataflow.googleapis.com"
}

resource "google_project_service" "pubsub" {
  project = google_project.project.project_id
  service = "pubsub.googleapis.com"
}


# Cloud Storage
resource "google_storage_bucket" "bucket" {
  name          = "bucket274910"
  location      = "us-central1"
  project       = google_project.project.project_id
}

resource "google_storage_bucket_object" "producer_source" {
  name   = "producer-source.zip"
  bucket = google_storage_bucket.bucket.name
  source = "../producer-source.zip"
}


# BigQuery
resource "google_bigquery_dataset" "dataset" {
  dataset_id = "target_dataset"
  project    = google_project.project.project_id
}

resource "google_bigquery_table" "target_table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "target_table"
  project    = google_project.project.project_id

  schema = jsonencode([
    {
      name = "event_type"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "timestamp"
      type = "TIMESTAMP"
      mode = "NULLABLE"
    },
    {
      name: "data",
      type: "RECORD",
      mode: "NULLABLE",
      fields: [
          { "name": "user_id", "type": "STRING", "mode": "NULLABLE" },
          { "name": "action",  "type": "STRING", "mode": "NULLABLE" },
          { "name": "platform","type": "STRING", "mode": "NULLABLE" }
      ]
}
  ])

  deletion_protection = false
}


# Pub/Sub
resource "google_pubsub_topic" "topic" {
  name    = "topic"
  project = google_project.project.project_id
}

resource "google_pubsub_subscription" "subscription" {
  name    = "subscription"
  topic   = google_pubsub_topic.topic.id
  project = google_project.project.project_id
}

resource "google_pubsub_topic_iam_member" "function_publisher" {
  topic  = google_pubsub_topic.topic.id
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:dwiac-0001@appspot.gserviceaccount.com"
}


# Dataflow
resource "google_dataflow_flex_template_job" "pubsub_to_bq" {
  provider = google-beta
  name     = "pubsub-to-bq"
  region   = var.region
  project  = google_project.project.project_id

  container_spec_gcs_path = "gs://dataflow-templates-us-central1/latest/flex/PubSub_to_BigQuery_Flex"

  parameters = {
    inputSubscription     = "projects/${google_project.project.project_id}/subscriptions/${google_pubsub_subscription.subscription.name}"
    outputTableSpec       = "${google_project.project.project_id}:${google_bigquery_dataset.dataset.dataset_id}.${google_bigquery_table.target_table.table_id}"
    outputDeadletterTable = "${google_project.project.project_id}:${google_bigquery_dataset.dataset.dataset_id}.deadletter_table"
  }

  temp_location = "gs://${google_storage_bucket.bucket.name}/temp/"

  on_delete = "cancel"

  depends_on = [
    google_project_service.dataflow,
    google_bigquery_table.target_table,
    google_pubsub_subscription.subscription
  ]
}


# Cloud Functions
resource "google_cloudfunctions_function" "event_producer" {
  name        = "event-producer"
  project     = google_project.project.project_id
  runtime     = "python311"
  region      = var.region
  entry_point = "publish_event"
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.producer_source.name
  trigger_http = true
  available_memory_mb = 128
  timeout = 60

  environment_variables = {
    GCP_PROJECT  = google_project.project.project_id
    PUBSUB_TOPIC = google_pubsub_topic.topic.name
  }

  lifecycle {
    replace_triggered_by = [
      google_storage_bucket_object.producer_source
    ]
  }

  depends_on = [
    google_project_service.cloud_functions,
    google_project_service.artifact_registry,
    google_project_service.cloud_build,
    google_project_service.pubsub,
    google_storage_bucket_object.producer_source
  ]
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_project.project.project_id
  region         = google_cloudfunctions_function.event_producer.region
  cloud_function = google_cloudfunctions_function.event_producer.name

  role   = "roles/cloudfunctions.invoker"
  member = "user:${var.personal_email}"
}


# Cloud Scheduler
resource "google_cloud_scheduler_job" "schedule_producer" {
  name      = "trigger-producer"
  project   = google_project.project.project_id
  region    = var.region
  schedule  = "* * * * *"
  time_zone = "UTC"

  http_target {
    uri = google_cloudfunctions_function.event_producer.https_trigger_url
    http_method = "GET"

    oidc_token {
      service_account_email = google_cloudfunctions_function.event_producer.service_account_email
      # audience = "https://us-central1-dwiac-0001.cloudfunctions.net/event-producer"  # todo: avoid using this lol
    }
  }

  depends_on = [
    google_project_service.cloud_scheduler
  ]
}

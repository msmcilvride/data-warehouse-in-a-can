# Define provider
provider "google-beta" {
  region      = var.region
}


# Create the project and assign a billing account
data "google_billing_account" "account" {
  display_name = var.billing_account_name
  open         = true
}

resource "google_project" "project" {
  name            = var.project_name
  project_id      = var.project_id
  billing_account = data.google_billing_account.account.id
}


# Enable APIs
resource "google_project_service" "spanner" {
  project = google_project.project.project_id
  service = "spanner.googleapis.com"
  disable_on_destroy = false
}


# Spanner
resource "google_spanner_instance" "graph" {
  name = "graph-demo"
  display_name = "Spanner Graph"
  config = "regional-us-central1"
  project = google_project.project.project_id
  num_nodes = 1
  edition = "ENTERPRISE"

  depends_on = [
    google_project_service.spanner
  ]
}

resource "google_spanner_database" "database" {
  instance = google_spanner_instance.graph.name
  name     = "finance-graph-db"
  project  = google_project.project.project_id
  deletion_protection = false
  ddl = split(";\n", file("../spanner_schema.ddl"))
}

# resource "null_resource" "property_graph" {
#   provisioner "local-exec" {
#     command = <<EOT
#       gcloud spanner databases ddl update finance-graph-db \
#         --instance=${google_spanner_instance.graph.name} \
#         --ddl-file=../spanner_schema.ddl \
#         --project=${var.project_id}
#     EOT
#   }
#
#   depends_on = [google_spanner_database.database]
# }


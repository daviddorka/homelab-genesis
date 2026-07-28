output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "zone" {
  value = var.zone
}

output "region" {
  value = var.region
}

output "get_credentials_command" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${var.zone} --project ${var.project_id}"
}

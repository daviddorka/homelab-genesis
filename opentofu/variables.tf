variable "project_id" {
  description = "The GCP project ID where the cluster will be created."
  type        = string
}

variable "region" {
  description = "The GCP region for the cluster."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The GCP zone for the primary node pool."
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
  default     = "homelab-genesis"
}

variable "node_count" {
  description = "Number of nodes in the default node pool."
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for the default node pool."
  type        = string
  default     = "e2-standard-2"
}

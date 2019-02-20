variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west1"
}

variable zone {
  description = "Zone"
  default     = "europe-west1-b"
}

variable cluster_name {
  description = "Kubernetes cluster name"
}

variable cluster_node_count {
  description = "Kubernetes cluster node count"
  default     = 3
}

variable cluster_auth_username {
  description = "Kubernetes cluster master auth username"
}
variable cluster_auth_password {
  description = "Kubernetes cluster master auth password"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}



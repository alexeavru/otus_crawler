variable project {
  description = "Project ID"
  default     = "docker-223416"
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
  default     = "crawler-cluster"
}

variable cluster_node_count {
  description = "Kubernetes cluster node count"
  default     = 3
}

variable cluster_auth_username {
  description = "Kubernetes cluster master auth username"
  default     = "boygruv"
}
variable cluster_auth_password {
  description = "Kubernetes cluster master auth password"
  default     = "Qwertyuiop1234567890"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
  default     = "~/.ssh/appuser.pub"
}



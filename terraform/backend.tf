terraform {
  backend "gcs" {
    bucket  = "otus-crawler"
    prefix  = "terraform/state"
  }
}

resource "google_project" "data_gov_project" {
  project_id      = var.project_datagov
  billing_account = var.billing_id
  name            = var.project_datagov
}

resource "google_project" "data_stor_project" {
  project_id      = var.project_datasto
  billing_account = var.billing_id
  name            = var.project_datasto
}

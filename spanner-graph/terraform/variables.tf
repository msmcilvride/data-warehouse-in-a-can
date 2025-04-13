variable "billing_account_name" {
  type        = string
  description = "The name of the billing account."
}

variable "personal_email" {
  type        = string
  description = "Your personal IAM email address."
}

variable "project_id" {
  type        = string
  description = "The ID to use for the new project."
}

variable "project_name" {
  type        = string
  description = "The name to use for the new project."
}

variable "region" {
  type        = string
  description = "The region of the project."
}

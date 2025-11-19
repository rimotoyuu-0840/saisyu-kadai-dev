variable "github_owner" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "github_branch" {
  type    = string
  default = "dev"
}

variable "github_oauth_token" {
  type      = string
  sensitive = true
}

variable "ecr_repository_url" {
  type = string
}

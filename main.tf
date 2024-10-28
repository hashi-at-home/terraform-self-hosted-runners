terraform {
  required_version = "~> 1.9"
  backend "consul" {
    path = "terraform/hashi-at-home/runners"
  }
  required_providers {
    # We need github to provide access to github
    github = {
      source  = "integrations/github"
      version = "~> 6"
    }
    # we're going to need vault to read and write secrets
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4"
    }
    # Cloudflare will be used to create a few
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2"
    }
  }
}

provider "vault" {}

# Use vault to get the secrets for configuring the other providers
data "vault_kv_secret_v2" "github" {
  mount = "hashiatho.me-v2"
  name  = "github"
}

data "vault_kv_secret_v2" "cloudflare" {
  mount = "hashiatho.me-v2"
  name  = "cloudflare"
}

provider "cloudflare" {
  api_token = data.vault_kv_secret_v2.cloudflare.data.api_token
}

# resource "vault_generic_endpoint" "github_token" {
#   path                 = "/github_personal_tokens/token"
#   ignore_absent_fields = true
#   data_json            = jsonencode({ "installation_id" = 44668070 })
# }


provider "github" {
  token = data.vault_kv_secret_v2.github.data.gh_token
  # token = jsondecode(vault_generic_endpoint.github_token.data_json).token
  owner = "hashi-at-home"
  alias = "hah"
}

provider "github" {
  token = data.vault_kv_secret_v2.github.data.gh_token
  # token = jsondecode(vault_generic_endpoint.github_token.data_json).token
  owner = "brucellino"
  alias = "mine"
}

provider "nomad" {}


module "hah" {
  providers = {
    github = github.hah
  }
  source            = "brucellino/nomad-webhooks/github"
  version           = "2.0.1"
  github_username   = "hashi-at-home"
  org               = true
  include_archived  = false
  cloudflare_domain = "hashiatho.me"
}

module "mine" {
  providers = {
    github = github.mine
  }
  source            = "brucellino/nomad-webhooks/github"
  version           = "2.0.1"
  github_username   = "brucellino"
  org               = false
  include_archived  = false
  cloudflare_domain = "brucellino.dev"
}

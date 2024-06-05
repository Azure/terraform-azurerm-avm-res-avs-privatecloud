terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.105"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    template = {
      source = "hashicorp/template"
      version = "~> 2.2"
    }
    time    = {
      source = "hashicorp/time"
      version = "~> 0.11"
    }
  }
}

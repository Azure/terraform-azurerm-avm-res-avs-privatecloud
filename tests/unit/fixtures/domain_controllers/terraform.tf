terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    modtm = {
      source  = "Azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

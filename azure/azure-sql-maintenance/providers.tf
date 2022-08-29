terraform {

  required_version = "1.2.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.13.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.8.0"

    }
  }
  backend "yourbackend" {
    #set up as per your own preference no need to have a special backend for this runbook
  }
}
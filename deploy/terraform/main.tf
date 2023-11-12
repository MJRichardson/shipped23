terraform {
    required_providers {
        octopusdeploy = {
          source  = "OctopusDeployLabs/octopusdeploy"
        }
        azurerm = {
          source  = "hashicorp/azurerm"
          version = "~>3.0"
        }
    }
    backend "azurerm" {
      resource_group_name  = "shipped23-tfstate"
      storage_account_name = "tfstateshipped23"
      container_name       = "tfstate"
      key                  = "terraform.tfstate"
    }
}

provider "octopusdeploy" {
  address   = var.server_url
  api_key   = var.apiKey
  space_id  = var.space
}

data "octopusdeploy_projects" "shipped_project" {
  name                   = "SHIPPED23"
}

resource "octopusdeploy_environment" "branch_environment" {
  name  = "${terraform.workspace}"
}

resource "octopusdeploy_lifecycle" "branch_lifecycle" {
  name        = "shipped23_branch_${terraform.workspace}"

  release_retention_policy {
    quantity_to_keep = 5
    unit             = "Days"
  }

  phase {
    name                            = "${octopusdeploy_environment.branch_environment.name}"
    automatic_deployment_targets    = ["${octopusdeploy_environment.branch_environment.id}"]
  }

  depends_on = [octopusdeploy_environment.branch_environment]
}

resource "octopusdeploy_channel" "branch_channel" {
  name                  = "${terraform.workspace}"
  project_id            = "${data.octopusdeploy_projects.shipped_project.projects[0].id}"
  lifecycle_id          = "${octopusdeploy_lifecycle.branch_lifecycle.id}"
}
resource "octopusdeploy_kubernetes_cluster_deployment_target" "k8s-dev" {
  cluster_url                       = ""
  default_worker_pool_id            = "WorkerPools-386"
  environments                      = ["${octopusdeploy_environment.branch_environment.id}"]
  machine_policy_id                 = "MachinePolicies-305"
  name                              = "SHIPPED23 - K8s - ${octopusdeploy_environment.branch_environment.name}"
  roles                             = ["shipped23-k8s"]
  azure_service_principal_authentication {
    account_id             = "Accounts-182"
    cluster_name           = "shipped23-dev"
    cluster_resource_group = "shipped23-dev"
  }
  container {
    feed_id = "Feeds-1487"
    image   = "octopuslabs/k8s-workertools:1.26.3-ubuntu.2204"
  }
}

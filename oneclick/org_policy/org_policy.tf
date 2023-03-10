/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#############################################################################################################################################################
#ORGANIZATION POLICIES/CONSTRAINT REQUIRED FOR THE RESOURCES/PRODUCT WE ARE USING                                                                           #
#INSIDE OUR TERRAFORM SCRIPTS.                                                                                                                              #
#ALLOWS MANAGEMENT OF ORGANIZATION POLICIES FOR A GOOGLE CLOUD PROJECT                                                                                      #      
#BOOLEAN CONSTRAINT POLICY CAN BE USED TO EXPLICITLY ALLOW A PARTICULAR CONSTRAINT ON AN INDIVIDUAL PROJECT, REGARDLESS OF HIGHER LEVEL POLICIES            #
#LIST CONSTRAINT POLICY THAT CAN DEFINE SPECIFIC VALUES THAT ARE ALLOWED OR DENIED FOR THE GIVEN CONSTRAINT. IT CAN ALSO BE USED TO ALLOW OR DENY ALL VALUES#
#############################################################################################################################################################

/******************************************
1. Activate APIs - Data Storage Project
 *****************************************/
module "activate_service_apis" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  project_id                     = var.project_id_storage
  enable_apis                 = true

  activate_apis = [
    "orgpolicy.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "bigquery.googleapis.com", 
    "storage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "dlp.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "bigquerydatatransfer.googleapis.com"
    ]

  disable_services_on_destroy = false
  
}


/******************************************
1. Project Services Configuration - Data Governance Project 
 *****************************************/
module "activate_service_apis_dg" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  project_id                     = var.project_id_governance
  enable_apis                 = true

  activate_apis = [
    "dataproc.googleapis.com",
    "dataflow.googleapis.com",
    "orgpolicy.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "containerregistry.googleapis.com",
    "bigquery.googleapis.com", 
    "storage.googleapis.com",
    "metastore.googleapis.com",
    "dataplex.googleapis.com",
    "datacatalog.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "composer.googleapis.com",
    "datapipelines.googleapis.com",
    "logging.googleapis.com",
    "cloudscheduler.googleapis.com",
    "monitoring.googleapis.com",
    "analyticshub.googleapis.com",
    "bigquerydatatransfer.googleapis.com"
    ]

  disable_services_on_destroy = false
  
}


/*******************************************
Introducing sleep to minimize errors from
dependencies having not completed
********************************************/
resource "time_sleep" "sleep_after_activate_service_apis" {
  create_duration = "60s"

  depends_on = [
    module.activate_service_apis
  ]
}

/******************************************
2. Project-scoped Org Policy Relaxing - Data Storage Project
*****************************************/

resource "google_project_organization_policy" "bool-policies-ds" {
  for_each = {
    "compute.requireOsLogin" : false,
    "compute.disableSerialPortLogging" : false,
    "compute.requireShieldedVm" : false
  }
  project    = var.project_id_storage
  constraint = format("constraints/%s", each.key)
  boolean_policy {
    enforced = each.value
  }

  depends_on = [
    time_sleep.sleep_after_activate_service_apis
  ]

}

resource "google_project_organization_policy" "list_policies-ds" {
  for_each = {
    "compute.vmCanIpForward" : true,
    "compute.vmExternalIpAccess" : true,
    "compute.restrictVpcPeering" : true
    "compute.trustedImageProjects" : true
  }
  project     = var.project_id_storage
  constraint = format("constraints/%s", each.key)
  list_policy {
    allow {
      all = each.value
    }
  }

  depends_on = [
    time_sleep.sleep_after_activate_service_apis
  ]

}


/******************************************
4. Project-scoped Org Policy Relaxing - Data Governance Project
*****************************************/

resource "google_project_organization_policy" "bool-policies-dg" {
  for_each = {
    "compute.requireOsLogin" : false,
    "compute.disableSerialPortLogging" : false,
    "compute.requireShieldedVm" : false,
    "iam.disableCrossProjectServiceAccountUsage" :false
  }
  project    = var.project_id_governance
  constraint = format("constraints/%s", each.key)
  boolean_policy {
    enforced = each.value
  }

  depends_on = [
    time_sleep.sleep_after_activate_service_apis
  ]

}

resource "google_project_organization_policy" "list_policies-dg" {
  for_each = {
    "compute.vmCanIpForward" : true,
    "compute.vmExternalIpAccess" : true,
    "compute.restrictVpcPeering" : true
    "compute.trustedImageProjects" : true
  }
  project     = var.project_id_governance
  constraint = format("constraints/%s", each.key)
  list_policy {
    allow {
      all = each.value
    }
  }

  depends_on = [
    time_sleep.sleep_after_activate_service_apis
  ]

}

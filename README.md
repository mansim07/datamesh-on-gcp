# datamesh-on-gcp
## Lab 1: Setup the argolis demo environment (~1 hr) 
1. Navigate back to the [Console](https://console.cloud.google.com) in incognitive mode. Ensure that you are logged in as admin@

2. Open Cloud Shell while logged in as admin@.

2. Create two new projects with the assigned billing account using the below method. One for data storage (called datastore from now on) and one for data governance (called datagov from now on)
 
    substitute {username} with your actual username (your corp email without @google.com), or the SMO sub-domain
    
* Find the organization ID.
    ```shell
    $ gcloud organizations list \
    --filter="displayName~{username}" \
    --format="value(name)"
    ```

* Create a new project using a unique project ID string.
    ```shell
    $ gcloud projects create {proj-id} \
    --organization={org-id}
    ```

* Find the billing ID.
    ```shell
    $ gcloud beta billing accounts list \
    --filter="displayName~${username}" \
    --format="value(name)"
    ```

* Associate the project with the billing ID.
    ```shell
    $ gcloud beta billing projects link {proj-id} \
    --billing-account={billing-id}
    ```


4.  Clone this repository in Cloud Shell

    ```shell
    git clone https://github.com/mansim07/datamesh-on-gcp
    ```

5.  Install necessary python libraries
     
     ```shell
        pip3 install google-cloud-storage
        pip3 install numpy
        pip3 install faker_credit_score
    ```

6. Terraform instructions here 

## Lab 2: Data Classification using DLP

## Lab 2: Discover Metadata

## Lab 3: Manging Security

## Lab 4: Data Curation

## Lab 5: Data Quality

## Lab 6: Data Refinement & Movement 

## Lab 7: Builing Data Products

## Lab 8: Tag templates & Bulk Tagging

## Lab 9: Data Lineage 

## Lab 9: Orcehstrate using Composer

Later: 

 - Create multiple personas/roles in CLoud Indentity  and manage persona based security 


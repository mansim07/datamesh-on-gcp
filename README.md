# datamesh-on-gcp
## Lab 1: Setup the argolis demo environment (~1 hr) 
1. Navigate back to the [Console](https://console.cloud.google.com) in incognitive mode. Ensure that you are logged in as admin@

2. Open Cloud Shell while logged in as admin@.

3. set up the environment variables.

    Make sure you run the RAND once and capture the  value 

    ``` 
    echo $(((RND=RANDOM<<15|RANDOM)))
    ```
    Set the static values 

    ```
    export RAND_ID=<value-from-above>
    export USERNAME=<your-corp-email-without-@google.com>
    ```

    Copy and execute 
    ```
    export PROJECT_DATAGOV=mbank-datagovernance-${RAND_ID}

    export PROJECT_DATASTO=mbank-datastorage-${RAND_ID}

    export ORG_ID=$(gcloud organizations list --filter="displayName~${USERNAME}" --format="value(name)")

    export BILLING_ID=$(gcloud beta billing accounts list --filter="displayName~${USERNAME}" --format="value(name)")

    ```



3. Create two new projects with the assigned billing account using the below commands: 
  * Create the projects 
    ```shell
    $ gcloud projects create ${PROJECT_DATAGOV} \
    --organization=${ORG_ID}

    $ gcloud projects create ${PROJECT_DATASTO} \
    --organization=${ORG_ID}

    ```

* Associate the project with the billing ID.
    ```shell
    $ gcloud beta billing projects link ${PROJECT_DATAGOV} \
    --billing-account=${BILLING_ID}

    $ gcloud beta billing projects link ${PROJECT_DATASTO} \
    --billing-account=${BILLING_ID}

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

## Lab 7: Building Data Products

## Lab 8: Tag templates & Bulk Tagging

## Lab 9: Data Lineage 

## Lab 9: Orcehstrate using Composer

Later: 

 - Create multiple personas/roles in CLoud Indentity  and manage persona based security 


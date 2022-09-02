# datamesh-on-gcp
## Lab 1: Setup the argolis demo environment (~1 hr) 
1. Navigate to the [Console](https://console.cloud.google.com) in incognitive mode. Ensure that you are logged in as admin@<ldap>.altostrat.com

2. Open Cloud Shell while logged in as admin@.

3.  Clone this repository in Cloud Shell

    ```shell
    git clone https://github.com/mansim07/datamesh-on-gcp
    ```

4. Set up the environment variables.

    Make sure you run the RAND once and capture the  value 

    ``` 
    echo $(((RND=RANDOM<<15|RANDOM)))
    export RAND_ID=<value-from-above>
    export USERNAME=<your-corp-email-without-@google.com>
    ```

    Copy and execute 
    ```
    echo "export PROJECT_DATAGOV=mbank-datagovernance-${RAND_ID}" >> ~/.profile

    echo "export PROJECT_DATASTO=mbank-datastorage-${RAND_ID}" >> ~/.profile

    echo "export ORG_ID=$(gcloud organizations list --filter='displayName~${USERNAME}' --format='value(name)')"  >> ~/.profile

    echo "export BILLING_ID=$(gcloud beta billing accounts list --filter='displayName~${USERNAME}' --format='value(name)')" >> ~/.profile

    ```

5. Create two new projects with the assigned billing account using the below commands: 
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

5.  Install necessary python libraries
     
     ```shell
    pip3 install google-cloud-storage
    pip3 install numpy
    pip3 install faker_credit_score
    ```

6. Use Terraform to setup the rest of the environment

    ```
    cd ./oneclick/

    bash deploy_helper.sh ${PROJECT_DATASTO} ${PROJECT_DATAGOV} ${USERNAME} ${RAND_ID}

    ```

## Lab 2: Data Classification using DLP

## Lab 3: Discover Metadata

## Lab 4: Manging Security

## Lab 5: Data Curation

[Data Curation Instructions](https://docs.google.com/document/d/1RZXgMViqdnaCpqiTVbbj07zOuWgo2nRNcwbdv-Zo1bs/edit?resourcekey=0-VLlLdyURPwx1iJd-Ih-Wfw)

## Lab 6: Data Quality

[Data Quality Lab Instructions](https://docs.google.com/document/d/17m6bBAVf51q3tvo7hdjBElac32_t8FR3olZH6vTOYhs/edit#heading=h.10b13csq101)

## Lab 7: Data Refinement & Movement 

## Lab 8: Building Data Products

## Lab 9: Tag templates & Bulk Tagging

## Lab 10: Data Lineage 

## Lab 11: Orcehstrate using Composer [Jay]
gsutil cp ./dag ./composer 


## Clean up 

delete the projects 




Later: 

 - Create multiple personas/roles in CLoud Indentity  and manage persona based security 


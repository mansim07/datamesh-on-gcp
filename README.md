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
    echo "export PROJECT_DATAGOV=mbank-datagovernance-${RAND_ID}" >> ~/.profile

    echo "export PROJECT_DATASTO=mbank-datastorage-${RAND_ID}" >> ~/.profile

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

6. Use Terraform to setup the rest of the environment
 * Go to org policy directory 
    ```
    cd  ./oneclick/org_policy
    ```
* Set the gcloud project id 
    ```
    gcloud config set project ${PROJECT_DATASTO}
    ```
*  Initialze terraform
    ```
    terraform init
    ```
*  Apply terraform
    ```
    terraform apply -auto-approve -var project_id=${PROJECT_DATASTO}
    ```
*  Clean up
    ```
    rm terraform*
    ```
* Now switch the governance project
    ```
    gcloud config set project ${PROJECT_DATAGOV}
    ```
* Initialize tf 
    ````
    terraform init
    ```
* Tf apply 

    ```
    terraform apply -auto-approve -var project_id=${PROJECT_DATAGOV}
    ```
* Go to the terraform directory   
    ```
    cd ./oneclick/demo-store/terraform project
    ```
* Set the project to the data storage 
   ```
    gcloud config set project ${PROJECT_DATASTO}
   ```
* Initialize Init  
    ```
    terraform init
    ```
* Apply  Tf. To get your public ip address from the command line run: curl https://ipinfo.io/ip
    ```
    terraform apply -auto-approve -var rand=${RAND} -var project_id=${PROJECT_DATASTO}  -var 'org_id=${ORG_ID}' -var 'user_ip_range=10.6.0.0/24'
    ```
* Switch the directory 
    ```
    cd ./oneclick/demo-gov/terraform
    ```
* Switch back to the datagov project 
   ```
   gcloud config set project ${PROJECT_DATAGOV}
   ```
* tf init 
    ```
    terraform init
    ```
* tf apply. To get your public ip address from the command line run: curl https://ipinfo.io/ip
    ```
    terraform apply -auto-approve -var rand=${RAND} -var project_id=${PROJECT_DATAGOV} -var datastore_project_id=${PROJECT_DATASTO} -var 'org_id=${PROJECT_DATASTO} -var 'user_ip_range=10.6.0.0/24'



## Lab 2: Data Classification using DLP

## Lab 2: Discover Metadata

## Lab 3: Manging Security

## Lab 4: Data Curation

## Lab 5: Data Quality

[Data Quality Lab Instructions](https://docs.google.com/document/d/17m6bBAVf51q3tvo7hdjBElac32_t8FR3olZH6vTOYhs/edit#heading=h.10b13csq101)

## Lab 6: Data Refinement & Movement 

[Data Refinement Instructions](https://docs.google.com/document/d/1RZXgMViqdnaCpqiTVbbj07zOuWgo2nRNcwbdv-Zo1bs/edit?resourcekey=0-VLlLdyURPwx1iJd-Ih-Wfw)

## Lab 7: Building Data Products

## Lab 8: Tag templates & Bulk Tagging

## Lab 9: Data Lineage 

## Lab 9: Orcehstrate using Composer


## Clean up 

## Multiple Runs and/or cleanup: (This DOES NOT WORK at the moment; lake deletion doesn't delete child objects).

- You can run terraform destory as shown below but note that the Lake/Zones/Assets will not be destroyed.
-- as of this version, you will have to create a new project if the Lakes, Zones, or Assets were successfully created.
-- To run terraform destroy: 
1. cd to the ./oneclick/org_policy folder
2. run:  terraform destroy -auto-approve -var project_id=&lt;your-project-id&gt;
3. cd to the ./oneclick/demo/terraform project
4. terraform destroy -auto-approve -var project_id=&lt;your-project-id&gt; -var 'org_id=&lt;your-ldap&gt;.altostrat.com' -var 'user_ip_range=10.6.0.0/24'



Later: 

 - Create multiple personas/roles in CLoud Indentity  and manage persona based security 


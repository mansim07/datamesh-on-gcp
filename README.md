# datamesh-on-gcp
## Lab 1: Setup the argolis demo environment (~1 hr) 
1. Navigate to the [Console](https://console.cloud.google.com) in incognitive mode. Ensure that you are logged in as admin@your-ldap.altostrat.com

2. Open Cloud Shell while logged in as admin@.

3.  Clone this repository in Cloud Shell

    ```bash
    git clone https://github.com/mansim07/datamesh-on-gcp
    ```

4. Set up the environment variables.

    Make sure you run the RAND once and capture the  value 

    ```bash
    echo $(((RND=RANDOM<<15|RANDOM)))
    ```

    Replace the necessary values **before you execute the below 2 commands** 
    
    ```bash
    echo "export RAND_ID=replace-value-from-above" >> ~/.profile
    ```

    ```bash
    echo "export USERNAME=your-corp-email-without-@google.com" >> ~/.profile
    ```

    Copy and execute the below commands. No changes are needed. 
    ```bash

    source ~/.profile 

    echo "export PROJECT_DATAGOV=mbdatagov-${RAND_ID}" >> ~/.profile

    echo "export PROJECT_DATASTO=mbdatastore-${RAND_ID}" >> ~/.profile

    echo "export ORG_ID=$(gcloud organizations list --filter="displayName~${USERNAME}" --format='value(name)')"  >> ~/.profile

    echo "export BILLING_ID=$(gcloud beta billing accounts list --filter="displayName~${USERNAME}" --format='value(name)')" >> ~/.profile

    ```
5. Validate the environment variables 

    ```bash
    cat ~/.profile 
    ```

    ![profile](/demo_artifacts/imgs/validate-profile.png)



6. Create two new projects with the assigned billing account using the below commands: 
  * Create the projects 
    ```bash
    source ~/.profile 

    gcloud projects create ${PROJECT_DATAGOV} \
    --organization=${ORG_ID}

    gcloud projects create ${PROJECT_DATASTO} \
    --organization=${ORG_ID}

    ```

* Associate the project with the billing ID.
    ```bash
    gcloud beta billing projects link ${PROJECT_DATAGOV} \
    --billing-account=${BILLING_ID}

    gcloud beta billing projects link ${PROJECT_DATASTO} \
    --billing-account=${BILLING_ID}

    ```

7.  Install necessary python libraries
     
     ```bash
    pip3 install google-cloud-storage
    pip3 install numpy
    pip3 install faker_credit_score
    ```

8.  Make sure your admin@&lt;ldap&gt;.altostrat.com account has the "Organization Administrator" role assigned.

9. Use Terraform to setup the rest of the environment
<BR>
    ```
    See this [link](https://docs.google.com/presentation/d/1ZsZQjxAGwxWtaULxSBmEt9JlSQ56sZBAmgpdNR2YxVo/edit?resourcekey=0-ZNjhxTU4vJbTGGHRyVTpXw#slide=id.gcba0bf71d3_0_16200) for a presentation on Terrafor setup Instructions

    ```bash
    cd ~/datamesh-on-gcp/oneclick/

    source ~/.profile  

    bash deploy-helper.sh ${PROJECT_DATASTO} ${PROJECT_DATAGOV} ${USERNAME} ${RAND_ID}

    ```

## Lab 2: Manging Data Security
Managing DATA Security is the main goal of this lab. You will learn how to design and manage security policies using Dataplex's UI and REST API as part of the lab. The purpose of the lab is to learn how to handle dispersed data security more effectively across data domains.

[Dataplex Security Lab Instructions](https://docs.google.com/document/d/1nTxmFyOp7DvNreaDKZ_92u8K-dot6N1fTqkLrlDsSt8/edit#)

## Lab 3: Data Curation
You will discover how to leverage common Dataplex templates to curate raw data and translate it into standardized formats like parquet and Avro in the Data Curation lane. This demonstrates how domain teams may quickly process data in a serverless manner and begin consuming it for testing purposes.  

[Data Curation Instructions](https://docs.google.com/document/d/1RZXgMViqdnaCpqiTVbbj07zOuWgo2nRNcwbdv-Zo1bs/edit?resourcekey=0-VLlLdyURPwx1iJd-Ih-Wfw)

## Lab 4: Data Quality
You will learn how to define and perform Data Quality jobs on raw data in the Data Quality lab, evaluate and understand the DQ findings, and construct a dashboard to assess and monitor DQ.

[Data Quality Lab Instructions](https://docs.google.com/document/d/17m6bBAVf51q3tvo7hdjBElac32_t8FR3olZH6vTOYhs/edit#heading=h.10b13csq101)


## Lab 5: Data Classification using DLP
You will use DLP Data Profiler in this lab so that it can automatically classify the BQ data, which will then be used by a Dataplex  to provide business tags/annotations.  

[Data Classification Lab Instructions](https://docs.google.com/document/d/1wpmEYUnb-HV1AaZEhOaP5OPbYzHwf287RsT64ejFWlY/edit?resourcekey=0-kkNXZtUeYPQ6Ws_IIQv9Qw#)


## Lab 6: Building Data Products
In this lab, you will learn how to use BigQuery through Composer to populate the data products using conventional SQL after using [Configuration-driven Dataproc Templates](https://github.com/GoogleCloudPlatform/dataproc-templates) to migrate the data (supports incremental load) from GCS to BQ.


[Building Data Products Lab Instructions](https://docs.google.com/document/d/1gGPmolk6JOnDSBYBgYzPOM3t3_6DENnii4GeyyCkCPI/edit?resourcekey=0-O9lOQA4sUt8KQUQSbRostA#)

## Lab 8: Tag templates & Bulk Tagging
You will learn how to create bulk tags on the Dataplex Data Product entity across domains using Composer in this lab after the Data Products have been acquired as part of the above lab.

[Business Metadata tagging in Dataplex Lab Instructions](https://docs.google.com/document/d/1CLDSniTsJ5IfM2TWA2VpVkYRDCyuerstjCfG8Okljxk/edit?resourcekey=0-X1QDcD1-RxvPoGwx5alsWA#)


## Lab 9: Metadata and data discovery
You will learn how to find data using the logical structure and business annotations of Dataplex in this lab. Lineage is not enabled as part of the Lab at the moment, but hopefully we can in the future.

[Metadata discovery in Dataplex Lab Instructions](https://docs.google.com/document/d/1e5K04nU7rW1I269xN2V0ZN41ycZ12Qnx0xi1RY1AAig/edit?resourcekey=0-LTM7gkGJhbA33I_FumzH6w#heading=h.10b13csq101)



## [Optional] Post Work

 - Create HMS and attach it to the lake. Follow the instructions [here](https://cloud.google.com/dataplex/docs/create-lake#metastore)
 - Create multiple personas/roles in CLoud Indentity and play around with the security policies 
 - Become more creative and share ideas 
 - Don't forget post-survey and feedback 

## Clean up 
Please make sure you clean up your environment

 ```bash
 #Remove lien if any
gcloud alpha resource-manager liens list --project ${PROJECT_DATAGOV}
gcloud alpha resource-manager liens delete $lien_id --project ${PROJECT_DATAGOV}
gcloud projects delete ${PROJECT_DATAGOV}
gcloud projects delete ${PROJECT_DATAGOV}
```
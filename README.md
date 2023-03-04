# datamesh-on-gcp
## Lab 1: Setup the argolis demo environment (~1 hr) 

1. Navigate to the [Console](https://console.cloud.google.com) in incognitive mode. Ensure that you are logged in as admin@your-ldap.altostrat.com

2. Open Cloud Shell while logged in as admin@.

   You would need to create Google Cloud's Application Default Credentials using

    ```bash
    gcloud auth application-default login
    ```
    
3.  Clone this repository in Cloud Shell

    ```bash
    git clone https://github.com/yadavj2008/datamesh-on-gcp
    cd datamesh-on-gcp
    ```

4. Bootstrap environment variables.

    Open the bootstrap-env.sh file and change the USERNAME based on your argolis env 

    Once eidted, execute the bootstrap-env.sh script to populate the env variables.
    
    ```source bootstrap-env.sh
    ```

5.  Make sure your admin@&lt;ldap&gt;.altostrat.com account has the "Organization Administrator" and "Organization Policy Administrator" roles assigned at the Organization Level.

6. Deploy the demo using deploy-helper.sh script( NOTE: all required env variables already been set by bootstrap-env.sh script in previous step)
    

    ```bash
    cd ~/datamesh-on-gcp/oneclick/
    echo $PROJECT_DATASTO $PROJECT_DATAGOV $USERNAME $RAND_ID
    bash deploy-helper.sh ${PROJECT_DATASTO} ${PROJECT_DATAGOV} ${USERNAME} ${RAND_ID}

    ```
7. Validate the Dataplex are created with the right number of assets. Go to Dataplex… Then Manage…  You should see 5 Lakes as Shown Below


    ![Dataplex Image](/demo_artifacts/imgs/Dataplex-ui.png)

8. Go to Composer… Then Environments…  Click on <your-project-id>-composer link..then click on 'Environment Variables'

    ![Composer Env](/demo_artifacts/imgs/Composer-env.png)

## Lab 2: Manging Data Security[IMPORTANT]
Managing Data Security is the main goal of this lab. You will learn how to design and manage security policies using Dataplex's UI and REST API as part of the lab. The purpose of the lab is to learn how to handle distributed data security more effectively across data domains.

**Make sure you run the security lab before moving on to other labs**

[Dataplex Security Lab Instructions](https://docs.google.com/document/d/1nTxmFyOp7DvNreaDKZ_92u8K-dot6N1fTqkLrlDsSt8/edit#)

## Lab 3: Data Curation
You will discover how to leverage common Dataplex templates to curate raw data and translate it into standardized formats like parquet and Avro in the Data Curation lane. This demonstrates how domain teams may quickly process data in a serverless manner and begin consuming it for testing purposes.  

[Data Curation Lab Instructions](https://docs.google.com/document/d/1RZXgMViqdnaCpqiTVbbj07zOuWgo2nRNcwbdv-Zo1bs/edit?resourcekey=0-VLlLdyURPwx1iJd-Ih-Wfw)

## Lab 4: Data Quality
You will learn how to define and perform Data Quality jobs on raw data in the Data Quality lab, evaluate and understand the DQ findings, and construct a dashboard to assess and monitor DQ.

[Data Quality Lab Instructions](https://docs.google.com/document/d/17m6bBAVf51q3tvo7hdjBElac32_t8FR3olZH6vTOYhs/edit#heading=h.10b13csq101)


## Lab 5: Data Classification using DLP
You will use DLP Data Profiler in this lab so that it can automatically classify the BQ data, which will then be used by a Dataplex  to provide business tags/annotations.  

[Data Classification Lab Instructions](https://docs.google.com/document/d/1wpmEYUnb-HV1AaZEhOaP5OPbYzHwf287RsT64ejFWlY/edit?resourcekey=0-kkNXZtUeYPQ6Ws_IIQv9Qw#)


## Lab 6: Building Data Products
In this lab, you will learn how to use BigQuery through Composer to populate the data products using conventional SQL after using [Configuration-driven Dataproc Templates](https://github.com/GoogleCloudPlatform/dataproc-templates) to migrate the data (supports incremental load) from GCS to BQ.


[Building Data Products Lab Instructions](https://docs.google.com/document/d/1gGPmolk6JOnDSBYBgYzPOM3t3_6DENnii4GeyyCkCPI/edit?resourcekey=0-O9lOQA4sUt8KQUQSbRostA#)

## Lab 7: Tag templates, Bulk Tagging & Data discovery
You will learn how to create bulk tags on the Dataplex Data Product entity across domains using Composer in this lab after the Data Products have been created as part of the above lab. You will learn how to find data using the logical structure and business annotations of Dataplex in this lab. Lineage is not enabled as part of the Lab at the moment, but hopefully we can in the future. You will use a custom [metadata tag library](https://github.com/mansim07/datamesh-templates/tree/main/metadata-tagmanager) to create 4 predefined tag templates - Data Classification, Data Quality, Data Exchange and Data product info(Onwership) 

[Business Metadata tagging and discovery in Dataplex Lab Instructions](https://docs.google.com/document/d/1CLDSniTsJ5IfM2TWA2VpVkYRDCyuerstjCfG8Okljxk/edit?resourcekey=0-X1QDcD1-RxvPoGwx5alsWA#)



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
gcloud alpha resource-manager liens delete <your lien-id from previous step> --project ${PROJECT_DATAGOV}
gcloud projects delete ${PROJECT_DATAGOV}
gcloud projects delete ${PROJECT_DATAGOV}
```

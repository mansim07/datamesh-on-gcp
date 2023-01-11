# datamesh-on-gcp
## Lab 1: Setup the argolis demo environment (~1 hr) 
1. Navigate to the [Console](https://console.cloud.google.com) 

2. Select an existing project or create a new one

3. Open Cloud Shell

4.  Clone this repository in Cloud Shell

    ```bash
    git clone https://github.com/mansim07/datamesh-on-gcp -b single_project
    ```

5. Set up the environment variables.

 
    ```bash
    echo "export USERNAME=your-email" >> ~/.profile
    echo "export PROJECT_ID=$(gcloud config get-value project)"
    ```
<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<B> You should use your fully qualified email address (e.g. joe.user@gmail.com)</B>
<BR>
<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;To get the currently logged in email address, run: 'gcloud auth list as' below: <BR> <BR>
    <pre>
    gcloud auth list
 
    Credentialed Accounts

    ACTIVE: *
    ACCOUNT: joe.user@jgmail.com
    </pre>
    <BR>
    <BR>

6. Validate the environment variables 

    ```bash
    cat ~/.profile 
    ```

    ![profile](/demo_artifacts/imgs/validate-profile.png)


7.  Install necessary python libraries
     
     ```bash
    pip3 install google-cloud-storage
    pip3 install numpy
    pip3 install faker_credit_score
    ```

8.  Make sure you have the appropriate Dataplex quotas for the following: 
<BR>
    <pre>
    ## dataplex.googleapis.com/zones in region:us-central1 should be at least 20
    ## dataplex.googleapis.com/lakes in region:us-central1 should be at least 5
    </pre>
<BR>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;You can view these settings at https://console.cloud.google.com/iam-admin/quotas and then enter the filters as shown below:<BR>
    ![quotas](/demo_artifacts/imgs/quotas.png)
<BR>

9. Use Terraform to setup the rest of the environment <BR>
    
    [Optional - Use Terraform Setup Instructions](https://docs.google.com/presentation/d/1ZsZQjxAGwxWtaULxSBmEt9JlSQ56sZBAmgpdNR2YxVo/edit)


    ```bash
    cd ~/datamesh-on-gcp/oneclick/

    source ~/.profile  

    bash deploy-helper.sh ${PROJECT_ID} ${USERNAME}

    ```
10. Validate the Dataplex are created with the right number of assets. Go to Dataplex… Then Manage…  You should see 5 Lakes as Shown Below


    ![Dataplex Image](/demo_artifacts/imgs/Dataplex-ui.png)

11. Go to Composer… Then Environments…  Click on <your-project-id>-composer link..then click on 'Environment Variables'

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
gcloud projects delete ${PROJECT_ID}
gcloud projects delete ${PROJECT_ID}
```

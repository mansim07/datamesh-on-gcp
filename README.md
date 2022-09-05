# datamesh-on-gcp
## Lab 1: Setup the argolis demo environment (~1 hr) 
1. Navigate to the [Console](https://console.cloud.google.com) in incognitive mode. Ensure that you are logged in as admin@<ldap>.altostrat.com

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

    ```bash
    cd ~/datamesh-on-gcp/oneclick/

    source ~/.profile  

    bash deploy-helper.sh ${PROJECT_DATASTO} ${PROJECT_DATAGOV} ${USERNAME} ${RAND_ID}

    ```

## Lab 2: Manging Data Security
[Dataplex Security Lab](https://docs.google.com/document/d/1nTxmFyOp7DvNreaDKZ_92u8K-dot6N1fTqkLrlDsSt8/edit#)

## Lab 3: Data Curation

[Data Curation Instructions](https://docs.google.com/document/d/1RZXgMViqdnaCpqiTVbbj07zOuWgo2nRNcwbdv-Zo1bs/edit?resourcekey=0-VLlLdyURPwx1iJd-Ih-Wfw)

## Lab 4: Data Quality

[Data Quality Lab Instructions](https://docs.google.com/document/d/17m6bBAVf51q3tvo7hdjBElac32_t8FR3olZH6vTOYhs/edit#heading=h.10b13csq101)


## Lab 5: Data Classification using DLP
[Data Classification Lab Instructions](https://docs.google.com/document/d/1wpmEYUnb-HV1AaZEhOaP5OPbYzHwf287RsT64ejFWlY/edit?resourcekey=0-kkNXZtUeYPQ6Ws_IIQv9Qw#)


## Lab 6: Building Data Products

[Building Data Products Lab Instructions](https://docs.google.com/document/d/1gGPmolk6JOnDSBYBgYzPOM3t3_6DENnii4GeyyCkCPI/edit?resourcekey=0-O9lOQA4sUt8KQUQSbRostA#)


## Lab 7: Metadata discovery
[Metadata discovery in Dataplex](https://docs.google.com/document/d/1e5K04nU7rW1I269xN2V0ZN41ycZ12Qnx0xi1RY1AAig/edit?resourcekey=0-LTM7gkGJhbA33I_FumzH6w#heading=h.10b13csq101)

## Lab 8: Tag templates & Bulk Tagging

[Business Metadata tagging in Dataplex](https://docs.google.com/document/d/1CLDSniTsJ5IfM2TWA2VpVkYRDCyuerstjCfG8Okljxk/edit?resourcekey=0-X1QDcD1-RxvPoGwx5alsWA#)

## Lab 9:  Orchestrate using Composer [Jay]

[Business Metadata tagging in Dataplex](https://docs.google.com/document/d/1CLDSniTsJ5IfM2TWA2VpVkYRDCyuerstjCfG8Okljxk/edit?resourcekey=0-X1QDcD1-RxvPoGwx5alsWA#)



## Clean up 

Delete both the projects 


## Post Work 

 - Create HMS and attach it to the lake. Follow the instructions here
 - Create multiple personas/roles in CLoud Indentity and plat around with the security policies 
 - Become more creative and share ideas 
 - Don't forget Post-survey and product feedback 


#Issues: 
#│ ERROR: (gcloud.dataplex.lakes.create) Status code: 429. Quota exceeded for quota metric 'API requests without their own specific quota config' and limit 'API requests without
#│ their own specific quota config per minute per user per region' of service 'dataplex.googleapis.com' for consumer 'project_number:372712865721'..
#

#Resolution: Enable a fresh environment
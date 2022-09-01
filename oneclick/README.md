# About

This repository contains the oneclick automation that can be used to deploy the Dataplex demo.

<pre>
There are two terraform projects (as required by the go/demos format):<BR>
|org_policy | 
| :- org_policy.tf | 
| :- variables.tf |
| :- versions.tf |
| demo |
| :- terraform | 
| :-- main.tf | 
| :-- variables.tf |
| :-- versions.tf |
| :-- modules |
</pre>

## Before running terraform:
1. create two projects, 
    * one for data storage (called datastore from now on)
    * one for data governance (called datagov from now on)
2. clone this repository in Cloud Shell (git clone https://github.com/mansim07/datamesh-on-gcp)
3. install necessary python libraries
    * pip3 install google-cloud-storage
    * pip3 install numpy
    * pip3 install faker_credit_score 

## Authentication (if necessary):
If you are using Cloud Shell, you can skip to the next step.  If not, do the following:

- Run: gcloud auth application-default login
- A link will pop up in the browser
- Copy the link to an incognito window and authenticate with your Argolis Account


## To run terraform do the following:

1. generate a random number and save to a variable:
    * RAND=$(((RND=RANDOM<<15|RANDOM)))
2. cd to the ./oneclick/org_policy folder
3. run: gcloud config set project &lt;your-datastor-project-id&gt;
4. run: terraform init
5. run:  terraform apply -auto-approve -var project_id=&lt;your-datastore-project-id&gt;
6. run: rm terraform*
7. run: gcloud config set project &lt;your-datagov-project-id&gt
8. run: terraform init
9. run:  terraform apply -auto-approve -var project_id=&lt;your-datagov-project-id&gt;
10. cd to the ./oneclick/demo-store/terraform project
11. run: gcloud config set project &lt;your-datastor-project-id&gt;
12. run: terraform init
13. terraform apply -auto-approve -var rand=${RAND} -var project_id=&lt;your-datastore-project-id&gt;  -var 'org_id=&lt;your-ldap&gt;.altostrat.com' -var 'user_ip_range=10.6.0.0/24'
14. cd to the ./oneclick/demo-gov/terraform project
15. run: gcloud config set project &lt;your-datagov-project-id&gt
16. run: terraform init
17. terraform apply -auto-approve -var rand=${RAND} -var project_id=&lt;your-datagov-project-id&gt; -var datastore_project_id=&lt;your-datastore-project-id&gt; -var 'org_id=&lt;your-ldap&gt;.altostrat.com' -var 'user_ip_range=10.6.0.0/24'


To get your public ip address from the command line run: curl https://ipinfo.io/ip

## Multiple Runs and/or cleanup: (This DOES NOT WORK at the moment; lake deletion doesn't delete child objects).

- You can run terraform destory as shown below but note that the Lake/Zones/Assets will not be destroyed.
-- as of this version, you will have to create a new project if the Lakes, Zones, or Assets were successfully created.
-- To run terraform destroy: 
1. cd to the ./oneclick/org_policy folder
2. run:  terraform destroy -auto-approve -var project_id=&lt;your-project-id&gt;
3. cd to the ./oneclick/demo/terraform project
4. terraform destroy -auto-approve -var project_id=&lt;your-project-id&gt; -var 'org_id=&lt;your-ldap&gt;.altostrat.com' -var 'user_ip_range=10.6.0.0/24'

OR

Do a manual cleanup:
1. cd to the ./oneclick/org_policy folder
2. run:  rm -rf terraform*
3. cd to the ./oneclick/demo-gov/terraform project
4. run:  rm -rf terraform*
5. cd to the ./oneclick/demo-store/terraform project
6. run:  rm -rf terraform*
7. run:  rm -rf datamesh-datagenerator
8. delete datagov and datastore projects via UI




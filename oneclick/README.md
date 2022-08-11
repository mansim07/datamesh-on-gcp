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
1. clone this repository in Cloud Shell (git clone https://github.com/mansim07/datamesh-on-gcp)
2. install necessary python libraries
    * pip3 install google-cloud-storage
    * pip3 install numpy
    * pip3 install faker_credit_score 

## Authentication (if necessary):
If you are using Cloud Shell, you can skip to the next step.  If not, do the following:

- Run: gcloud auth application-default login
- A link will pop up in the browser
- Copy the link to an incognito window and authenticate with your Argolis Account


## To run terraform do the following:

1. cd to the ./oneclick/org_policy folder
2. run: terraform init
3. run:  terraform apply -auto-approve -var project_id=&lt;your-project-id&gt;
4. cd to the ./oneclick/demo/terraform project
5. terraform apply -auto-approve -var project_id=&lt;your-project-id&gt; -var 'org_id=&lt;your-ldap&gt;.altostrat.com' -var 'user_ip_range=0.6.0.0/24'

To get your public ip address from the command line run: curl https://ipinfo.io/ip

## Multiple Runs and/or cleanup:

- You can run terraform destory as shown below but note that the Lake/Zones/Assets will not be destroyed.
-- as of this version, you will have to create a new project if the Lakes, Zones, or Assets were successfully created.
-- To run terraform destroy: 
1. cd to the ./oneclick/org_policy folder
2. run:  terraform destroy -auto-approve -var project_id=&lt;your-project-id&gt;
3. cd to the ./oneclick/demo/terraform project
4. terraform destroy -auto-approve -var project_id=&lt;your-project-id&gt; -var 'org_id=&lt;your-ldap&gt;.altostrat.com' -var 'user_ip_range=0.6.0.0/24'

OR

Do a manual cleanup:
1. cd to the ./oneclick/org_policy folder
2. run:  rm -rf terraform*
3. cd to the ./oneclick/demo/terraform project
4. run:  rm -rf terraform*





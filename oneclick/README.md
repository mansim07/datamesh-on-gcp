# About

This repository contains the oneclick automation that can be used to deploy the Dataplex demo.

There are two terraform projects (as required by the go/demos format):
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


## Before running terraform:
If you are using Cloud Shell, you can skip to the next step.  If not, do the following:

- Run: gcloud auth application-default login
- A link will pop up in the browser
- Copy the link to an incognito window and authenticate with your Argolis Account


## To run terraform do the following:

1. cd to the ./oneclick/org_policy folder
2. run: terraform init
3. run:  terraform apply -auto-approve -var project=<your-project-id>
4. cd to the ./oneclick/demo/terraform project
5. terraform apply -auto-approve -var project_id=<your-project-id> -var 'org_id=<your-ldap>.altostrat.com' -var 'user_ip_range=0.6.0.0/24'

To get your public ip address from the command line run: curl https://ipinfo.io/ip

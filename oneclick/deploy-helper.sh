#!/bin/bash
#set -x
if [ "$#" -ne 4 ]; then
    echo "Illegal number of parameters"
    echo "Usage: ./deploy_helper.sh <datastore-projectid> <datagov-projectid> <ldap> <randid>"
    echo "Example: ./deploy_helper.sh my-datastore my-datagov jayoleary 123"
    exit 1
fi
GCP_DATASTORE_PROJECT_ID=$1
GCP_DATAGOV_PROJECT_ID=$2
GCP_ARGOLIS_LDAP=$3
RAND=$4

#git clone https://github.com/mansim07/datamesh-on-gcp

#RAND=$(((RND=RANDOM<<15|RANDOM)))



echo "${GCP_DATASTORE_PROJECT_ID}"
cd ~/datamesh-on-gcp/oneclick/org_policy
gcloud config set project ${GCP_DATASTORE_PROJECT_ID}
terraform init
#terraform apply -auto-approve -var project_id=${GCP_DATASTORE_PROJECT_ID}
rm terraform*
gcloud config set project ${GCP_DATAGOV_PROJECT_ID}
terraform init
#terraform apply -auto-approve -var project_id=${GCP_DATAGOV_PROJECT_ID}
rm terraform*

cd ../../..
pwd
cd ~/datamesh-on-gcp/oneclick/demo-store/terraform
gcloud config set project ${GCP_DATASTORE_PROJECT_ID}
terraform init
#terraform apply -auto-approve -var rand=${RAND} -var project_id=${GCP_DATASTORE_PROJECT_ID} -var "org_id=${GCP_ARGOLIS_LDAP}.altostrat.com" -var 'user_ip_range=10.6.0.0/24'
cd ../../demo-gov/terraform
gcloud config set project ${GCP_DATAGOV_PROJECT_ID}
terraform init
#terraform apply -auto-approve -var rand=${RAND} -var project_id=${GCP_DATAGOV_PROJECT_ID} -var datastore_project_id=${GCP_DATASTORE_PROJECT_ID} -var "org_id=${GCP_ARGOLIS_LDAP}.altostrat.com" -var 'user_ip_range=10.6.0.0/24'

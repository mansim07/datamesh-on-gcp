#!/bin/bash
#set -x


echo "export PROJECT_DATAGOV=mb-governance-${RAND_ID}" >> ~/.profile

echo "export PROJECT_DATASTO=mb-storage-${RAND_ID}" >> ~/.profile

echo "export ORG_ID=$(gcloud organizations list --filter='displayName~${USERNAME}' --format='value(name)')"  >> ~/.profile

echo "export BILLING_ID=$(gcloud beta billing accounts list --filter='displayName~${USERNAME}' --format='value(name)')" >> ~/.profile


gcloud projects create ${PROJECT_DATAGOV} \
    --organization=${ORG_ID}

gcloud projects create ${PROJECT_DATASTO} \
    --organization=${ORG_ID}

gcloud beta billing projects link ${PROJECT_DATAGOV} \
    --billing-account=${BILLING_ID}

gcloud beta billing projects link ${PROJECT_DATASTO} \
    --billing-account=${BILLING_ID}


pip3 install google-cloud-storage
pip3 install numpy
pip3 install faker_credit_score
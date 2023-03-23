#Set your gcp admin account username
export USERNAME=jitendrayadav
#End


export RAND_ID=`echo $(((RND=RANDOM<<15|RANDOM)))`
export PROJECT_DATAGOV=mbdatagov-${RAND_ID}
export PROJECT_DATASTO=mbdatasto-${RAND_ID}
export ORG_ID=$(gcloud organizations list --filter="displayName~${USERNAME}" --format='value(name)')
export BILLING_ID=$(gcloud beta billing accounts list --filter="displayName~${USERNAME}" --format='value(name)')
export TF_VAR_project_datagov=$PROJECT_DATAGOV
export TF_VAR_project_datasto=$PROJECT_DATASTO
export TF_VAR_billing_id=$BILLING_ID
export TF_VAR_org_id=$ORG_ID

#Install required python libs(python3 needed)
pip3 install google-cloud-storage
pip3 install numpy
pip3 install faker_credit_score

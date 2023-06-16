
cp .env.template .env

source .env

terraform apply

ibmcloud login -r us-south -g default --apikey $TF_VAR_ibmcloud_api_key

ibmcloud ce project create --name $TF_VAR_resources_prefix-project

ibmcloud ce app create --name node-app --src . --str buildpacks --build-context-dir /examples/app-nodejs/ --env-from-secret app-secrets --env-from-secret apply-output

copy <code/>

ibmcloud ce secret create --name apply-output --from-env-file .apply.output.env

ibmcloud ce app update --name node-app --src . --str buildpacks --build-context-dir /examples/app-nodejs/ --env-from-secret app-secrets --env-from-secret apply-output

ibmcloud ce project delete --name $TF_VAR_resources_prefix-project
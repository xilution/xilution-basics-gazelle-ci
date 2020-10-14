#!/bin/bash -ex

awsAccountId=${CLIENT_AWS_ACCOUNT}
pipelineId=${GAZELLE_PIPELINE_ID}

terraform init \
  -backend-config="key=xilution-basics-gazelle/${pipelineId}/terraform.tfstate" \
  -backend-config="bucket=xilution-terraform-backend-state-bucket-${awsAccountId}" \
  -backend-config="dynamodb_table=xilution-terraform-backend-lock-table" \
  ./terraform/trunk

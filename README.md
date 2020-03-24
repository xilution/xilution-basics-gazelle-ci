# xilution-basics-gazelle-ci

## Prerequisites

1. Clone `https://github.com/xilution/xilution-scripts` and add root directory to your PATH environment variable.
1. Install [Terraform](https://www.terraform.io/)
1. The following environment variables need to be in scope.
    ```
    export XILUTION_ORGANIZATION_ID={Xilution Organization or Sub-organization ID}
    export GAZELLE_PIPELINE_ID={Gazelle Pipeline ID}
    export XILUTION_AWS_ACCOUNT=$AWS_PROD_ACCOUNT_ID
    export XILUTION_AWS_REGION=us-east-1
    export XILUTION_ENVIRONMENT=prod
    export CLIENT_AWS_ACCOUNT={Client AWS Account ID}
    export CLIENT_AWS_REGION=us-east-1
    
    ```

    Check the values
    ```
    echo $XILUTION_ORGANIZATION_ID
    echo $GAZELLE_PIPELINE_ID
    echo $XILUTION_AWS_ACCOUNT
    echo $XILUTION_AWS_REGION
    echo $XILUTION_ENVIRONMENT
    echo $CLIENT_AWS_ACCOUNT
    echo $CLIENT_AWS_REGION
    
    ```

## To pull the CodeBuild docker image

Run `make pull-docker-image`

## To init the submodules

Run `make submodules-init`

## To updated the submodules

Run `make submodules-update`

## To access to a client's account

```
unset AWS_PROFILE
unset AWS_REGION
update-xilution-mfa-profile.sh $AWS_SHARED_ACCOUNT_ID $AWS_USER_ID {mfa-code}
assume-client-role.sh $AWS_PROD_ACCOUNT_ID $CLIENT_AWS_ACCOUNT xilution-developer-role xilution-developer-role xilution-prod client-profile
aws sts get-caller-identity --profile client-profile
export AWS_PROFILE=client-profile
export AWS_REGION=$CLIENT_AWS_REGION

```

## Initialize terraform

Run `make init`

## Verify terraform

Run `make verify`

## To Test Pipeline Infrastructure Step

Run `make test-pipeline-infrastructure`

## To Uninstall the infrastructure

Run `./support/destroy-infrastructure.sh`

## To Launch a Support EC2 Instance

You can use the Support EC2 Instance to interact with EFS.
Once connected, you can run `cd /mnt/efs/fs1` to access the root of the filesystem.

Run `./support/launch-bastion.sh` to start a bastion ec2 instance.

Run `ssh -i ./key.pem -o "StrictHostKeyChecking=no" ec2-user@"$(yq r ./bastion.yaml public_dns_name)"` to start an bash session with the bastion.

Run `exit` to end the bastion bash session.

Run `./support/terminate-bastion.sh` to terminate the bastion ec2 instance.

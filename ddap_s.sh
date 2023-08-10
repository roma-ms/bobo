#!/bin/bash
# Bash Script to aid loging into EKS Cluster using OIDC
# https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/ 
# KubeLogin needs to be installed
# https://github.com/int128/kubelogin

# Set AWS Region
AWS_REGION=eu-west-2

while getopts e:s:n flag
do
    case "${flag}" in
        e) ENV=${OPTARG};;
        s) SECRET_ARN=${OPTARG};;
        n) CLUSTER_NAME=${OPTARG};;
    esac
done

# Get the EKS OIDC Secret - if one has not been specified
if [[ -z $SECRET_ARN ]]
then
  if [[ $ENV == "dev" ]]
  then
    echo "Dev Cluster Selected"
    SECRET_ARN="arn:aws:secretsmanager:eu-west-2:311339501963:secret:ddap-dev-eks-oidc-secret-rLXXF-vDn0kp"
  elif [[ $ENV == "test" ]]
  then
    echo "Test Cluster Selected"
    SECRET_ARN="arn:aws:secretsmanager:eu-west-2:208003755594:secret:ddap-test-eks-oidc-secret-ORfvD-bTqLP5" 
  elif [[ $ENV == "ops" ]]
  then
    echo "DevSecOps Cluster Selected"
    SECRET_ARN="arn:aws:secretsmanager:eu-west-2:341291358461:secret:ddap-ops-eks-oidc-secret-e9ZwS-sn2jaF"  
  elif [[ $ENV == "preprod" ]]
  then
    echo "PreProd Cluster Selected"
    SECRET_ARN="arn:aws:secretsmanager:eu-west-2:322459277664:secret:ddap-preprod-eks-oidc-secret-tTLIp-ENbDnH" 
  elif [[ $ENV == "prod" ]]
  then
    echo "Prod Cluster Selected"
    SECRET_ARN="arn:aws:secretsmanager:eu-west-2:647585978221:secret:ddap-prod-eks-oidc-secret-DHufp-XPq0NV" 
  fi
fi

if [[ -z $CLUSTER_NAME ]]
then
  CLUSTER_NAME="ddap-$ENV-eks"
fi

# Then pull the secret from aws...
OIDC_SECRET=$(aws secretsmanager get-secret-value --secret-id $SECRET_ARN --region $AWS_REGION --query SecretString --output text)
# Get Cluster bits
CLUSTER_CERT=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query cluster.certificateAuthority --output text) 
CLUSTER_ADDR=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query cluster.endpoint --output text) 
CLUSTER_ARN=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query cluster.arn --output text) 

# Create the cluster
kubectl config \
  set-cluster $CLUSTER_ARN \
  --server=$CLUSTER_ADDR \

# Cannot set this directly...
kubectl config set clusters.${CLUSTER_ARN}.certificate-authority-data $CLUSTER_CERT

# Create the oidc user
kubectl config set-credentials oidc-${ENV} \
  --exec-api-version=client.authentication.k8s.io/v1beta1 \
  --exec-command=kubectl \
  --exec-arg=oidc-login \
  --exec-arg=get-token \
  --exec-arg=--oidc-issuer-url=https://keycloak.ddap-ops.ice.mod.gov.uk/auth/realms/ddap \
  --exec-arg=--oidc-client-id=eks-ddap-${ENV}-cluster \
  --exec-arg=--oidc-client-secret=${OIDC_SECRET}

# Set the context
kubectl config \
  set-context ${CLUSTER_ARN}-oidc \
  --cluster=$CLUSTER_ARN \
  --user=oidc-${ENV}

# Use the context
kubectl config use-context ${CLUSTER_ARN}-oidc

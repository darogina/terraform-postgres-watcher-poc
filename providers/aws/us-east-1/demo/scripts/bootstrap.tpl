#!/bin/bash
set -e

echo "Updating yum..."
yum update -y

echo "Installing git..."
yum -y install git

echo "Insalling unzip..."
yum -y install unzip

echo "Installing AWS CLI..."
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
aws configure set region ${region}

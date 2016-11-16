#!/bin/bash
set -e

usage() {
  cat <<EOF
Generate SSL keys

Usage:
  $0 <PROJECT> <ENVIRONMENT>

Where PROJECT and ENVIRONMENT are specified in terraform.tfvars.
This will generate a .pem private key and a .pub public key in the directory specified.
EOF

  exit 1
}

PROJECT=$1
ENVIRONMENT=$2

if [ "x$PROJECT" == "x" ]; then
  echo
  echo "ERROR: Specify project as the first argument, e.g. qtility"
  echo
  usage
elif [ "x$ENVIRONMENT" == "x" ]; then
  echo
  echo "ERROR: Specify environment as the second argument, e.g. aws-us-east-1-prod"
  echo
  usage
fi

KEY=$PROJECT\-$ENVIRONMENT

if [ -s "$KEY.pem" ] && [ -s "$KEY.pub" ]; then
  echo Using existing key pair
else
  rm -rf $KEY*

  echo No key pair exists, generating new keys...
  
  while true
  do
      read -s -p "Enter passphrase (empty for no passphrase): " PASSPHRASE
      echo
      if [ -n "$PASSPHRASE" ]; then
          read -s -p "Enter same passphrase again: " PASSPHRASE2
          echo
          [ "$PASSPHRASE" = "$PASSPHRASE2" ] && break
          echo "Passphrases do not match.  Try again."
      else 
          break
      fi
  done
  
  ssh-keygen -t rsa -b 2048 -f $KEY -N "$PASSPHRASE"
  mv $KEY $KEY.pem
  chmod 400 $KEY.pem

  echo "Adding private key to authentication agent.  Enter same password one last time."
  ssh-add $KEY.pem
fi

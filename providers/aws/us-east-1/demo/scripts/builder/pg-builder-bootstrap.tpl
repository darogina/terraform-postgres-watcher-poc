#!/bin/bash
set -e

echo "Installing Postgres build dependencies..."
yum install -y bison-devel readline-devel zlib-devel openssl-devel wget
yum groupinstall -y 'Development Tools'

echo "Installing JQ for json parsing..."
curl -o /usr/bin/jq http://stedolan.github.io/jq/download/linux64/jq && chmod +x /usr/bin/jq

echo "Downloading pg-builder agent..."
aws s3 cp s3://${bucket_name}/${agent_key} ${working_dir}/${agent_key}
chmod +x /opt/pg-builder/${agent_key}

echo "Download pg-builder agent service..."
aws s3 cp s3://${bucket_name}/${service_key} /etc/systemd/system/${service_key}
chmod 664 /etc/systemd/system/${service_key}

echo "Create postgres user..."
adduser postgres

echo "Setting up environment for agent..."
su - postgres -c "aws configure set region ${region}"
touch ${log_file} && chown postgres:postgres ${log_file}
chown -R postgres:postgres ${working_dir}

echo "Starting pg-builder agent service..."
systemctl enable ${service_key}
systemctl start ${service_key}

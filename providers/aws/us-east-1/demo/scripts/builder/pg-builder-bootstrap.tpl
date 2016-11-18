#!/bin/bash
set -e

echo "Installing Postgres build dependencies..."
yum -y install bison-devel readline-devel zlib-devel openssl-devel wget rpm-build spectool perl-ExtUtils-Embed perl-devel python-devel tcl-devel e2fsprogs-devel libxml2-devel libxslt-devel pam-devel systemtap-sdt-devel libuuid-devel openldap-devel systemd-devel
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

#!/bin/bash
set -e

echo "Downloading pg-builder agent..."
aws s3 cp s3://${bucket_name}/${agent_key} /opt/pg-builder/${agent_key}
chmod +x /opt/pg-builder/${agent_key}

echo "Download pg-builder agent service..."
aws s3 cp s3://${bucket_name}/${service_key} /etc/systemd/system/${service_key}
chmod 664 /etc/systemd/system/${service_key}

echo "Starting pg-builder agent service..."
systemctl enable ${service_key}
systemctl start ${service_key}

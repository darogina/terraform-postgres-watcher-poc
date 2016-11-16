#!/bin/bash
set -e

echo "Downloading git watcher agent..."
aws s3 cp s3://${bucket_name}/${agent_key} /opt/git-watcher/${agent_key}
chmod +x /opt/git-watcher/${agent_key}

echo "Download git watcher agent service..."
aws s3 cp s3://${bucket_name}/${service_key} /etc/systemd/system/${service_key}
chmod 664 /etc/systemd/system/${service_key}

echo "Starting git watcher agent..."
systemctl enable git-watcher-agent.service
systemctl start git-watcher-agent.service

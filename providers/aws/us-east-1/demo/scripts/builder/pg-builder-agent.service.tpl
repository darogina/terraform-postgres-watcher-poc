#!/bin/sh

[Unit]
Description=Postgres Builder Agent

[Service]
ExecStart=/opt/pg-builder/${agent_key} /opt/pg-builder/repo ${sqs_url}
Restart=always

[Install]
WantedBy=default.target

#!/bin/sh

[Unit]
Description=Postgres Git Watch Agent

[Service]
ExecStart=/opt/git-watcher/${agent_key} /opt/git-watcher/repo ${sqs_url}
Restart=always

[Install]
WantedBy=default.target

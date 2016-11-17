#!/bin/sh

[Unit]
Description=Postgres Builder Agent

[Service]
User=postgres
ExecStart=${working_dir}/${agent_key} ${working_dir}/repo ${log_file} ${sqs_url}
Restart=always

[Install]
WantedBy=default.target

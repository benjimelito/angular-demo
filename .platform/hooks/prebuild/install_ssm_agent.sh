#!/bin/bash
set -e

if ! systemctl list-unit-files | grep -q amazon-ssm-agent; then
  sudo yum install -y amazon-ssm-agent
fi

sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
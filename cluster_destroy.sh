#!/bin/bash

set -e

cd terraform
TF_IN_AUTOMATION=1 terraform destroy -auto-approve

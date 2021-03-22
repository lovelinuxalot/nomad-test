#!/usr/bin/env bash

#Create SSH keys for all boxes
ssh-keygen -b 2048 -t rsa -f id_rsa -q -N ""

#Spin up vagrant boxes and provision them in order
vagrant up --no-provision && vagrant provision --provision-with consul && vagrant provision --provision-with all


#!/usr/bin/env bash

#Create SSH keys for all boxes
if [ ! -f "id.rsa" ] && [ ! -f "id_rsa.pub" ]; then
  ssh-keygen -b 2048 -t rsa -f id_rsa -q -N ""
  echo "SSH Key Created"
else
  echo "SSH Key already exists"
fi



#Spin up vagrant boxes and provision them in order
#vagrant up --no-provision && vagrant provision --provision-with consul && vagrant provision --provision-with all


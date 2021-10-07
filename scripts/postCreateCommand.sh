#!/bin/bash
set -e

# dev container uses a volume to persist the .azure folder - need to chown to container user
sudo chown -R node:node ~/.azure 

# run yarn for functions code
cd functions
yarn

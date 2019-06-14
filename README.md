# ulcc-core-docker

Docker builds for:

## ULCC core

Published image: https://hub.docker.com/r/researchtech/ulcc-core

To build:

* cp .env.template .env
* fill out the variables in .env
* docker-compose build

# An EPrints archive

To build:

* cp .env.template .env
* fill out the variables in .env
* docker-compose build
 
To run:

* docker-compose up

# Terraform

* ensure .env variables are in place
* build the latest image for the archive
* cd terraform
* cp terraform.tfvars.template terraform.tfvars
* fill out the variables in terraform.tfvars
* terraform init (just run the first time;  add --upgrade to upgrade terraform modules)
* terraform plan -out name.tfplan # where name is the same as the variable in tfvars
* terraform apply "name.tfplan"
* 
## TODO

Multi eprints build (prod / uat) - will need different ports

SSL and 443


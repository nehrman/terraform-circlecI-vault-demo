# Terraform-CircleCI-Vault-Demo

With this demo, the main objective is to illustrate how to migrate from an Terraform OSS workflow to Terraform Enterprise without changing everything. And, because, I like challenges, I decided also to integrate CircleCi with Vault to be able to request Azure Dynamic Secrets on the fly when pipeline is launched.

So, to summarize, that's the technologies and features that have been used :
- CircleCI Pipeline
- Vault with Custom Plugin for CircleCI Auth
- Azure Dynamic Secrets 
- Terraform Enhanced Backend
- Terraform Enterprise APIs

## What it's look like in CircleCI 

Screenshot of the Pipeline resulting from the config.yml file :

<img width="300" alt="CircleCI Pipeline Screenshot" src="https://github.com/nehrman/terraform-azure-windows/blob/master/images/CircleCI_workflow.png">

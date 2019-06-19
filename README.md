# Terraform-CircleCI-Vault-Demo

With this demo, the main objective is to illustrate how to migrate from an Terraform OSS workflow to Terraform Enterprise without changing everything. And, because, I like challenges, I decided also to integrate CircleCi with Vault to be able to request Azure Dynamic Secrets on the fly when pipeline is launched.

So, to summarize, that's the technologies and features that have been used :
- CircleCI Pipeline
- Vault with Custom Plugin for CircleCI Auth
- Azure Dynamic Secrets 
- Terraform Enhanced Backend
- Terraform Enterprise APIs

<img width="300" alt="CircleCI Pipeline Screenshot" src="https://github.com/nehrman/terraform-azure-windows/blob/master/images/CircleCi_Hashi_demo.png">

## What it's look like in CircleCI 

Screenshot of the Pipeline resulting from the config.yml file :

<img width="300" alt="CircleCI Pipeline Screenshot" src="https://github.com/nehrman/terraform-azure-windows/blob/master/images/CircleCI_workflow.png">

## How to build the demo ?

Now, let's talked about what do you need to recreate the demo environment, let's say, in Azure :

First, you need, of course, an appropriate **account** in Azure AD to be able to access Azure Portal and to configure Vault Dynamic Secrets.
- If not, create a free azure account here : https://azure.microsoft.com/fr-fr/free/
Create a VM on Azure and deploy a Vault instance (could be OSS) on it using that code : https://github.com/nehrman/vault-circleci-integration
- You should have something like this : 
    <img width="300" alt="CircleCI Pipeline Screenshot" src="https://github.com/nehrman/terraform-azure-windows/blob/master/images/Vault_CircleCi_Config.png">

Enable Azure Secret Engine with `vault auth enable -path=azure_demo azure` and configure Vault according to our documentation : https://www.vaultproject.io/docs/secrets/azure/index.html
Create a policy to authorize your CircleCI project to read creds from Azure Secret Engine :
```hcl
path "azure_demo/creds/my_role" {
  capabilities = ["read"]
}
```
Attach the policy to your project in the configuration of Vault CircleCI Auth Plugin :
```sh
$ vault write auth/vault-circleci-auth-plugin/map/projects/project_name value=policy_name
```
Now, we have to ask for a trial access to Terraform Cloud with Enterprise features. To do so, start here : https://www.hashicorp.com/go/terraform-enterprise-trial

When you received your account, connect to https://app.terraform.io and follow the [guide](https://www.terraform.io/docs/enterprise/getting-started/index.html) with :
- Creating an `organization` 
- Creating a `token`

Finally, we're gonna configure CircleCI. If you don't already have an account, just sign up [here](https://circleci.com/signup)

*To make things easier, create an account with your Github Account* :)

Now, follow these steps :
- Click on `+ Add Project`
<img width="300" alt="CircleCI Pipeline Screenshot" src="https://github.com/nehrman/terraform-azure-windows/blob/master/images/CircleCI_add_project.png">
- Select your project and click on `Set Up Project`
<img width="300" alt="CircleCI Pipeline Screenshot" src="https://github.com/nehrman/terraform-azure-windows/blob/master/images/CircleCI_setup_project.png">
- Finally, configure the Environment variables in your project 
<img width="300" alt="CircleCI Pipeline Screenshot" src="https://github.com/nehrman/terraform-azure-windows/blob/master/images/CircleCI_envvar.png">

*Bravo !!!!*, you're all set and ready to test the pipeline. 

## Special thanks

* **Marc Boudreau** - For his amazing work creating vault CircleCI Auth plugin [Github](https://github.com/marcboudreau)
* **Joern Stenkamp** - For helping me figure out with TFE variables creation [Github](https://github.com/joestack)

## Authors

* **Nicolas Ehrman** - *Initial work* - [Hashicorp](https://www.hashicorp.com)





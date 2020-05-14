#!/bin/bash
#set -e

Var_SubscriptionId='5c867415-9d26-445f-9a75-9bc80347d771'
Var_github='https://github.com/wkdang/sap-hana.git'
Var_SubscriptionId=$1
Var_ClientId=$2
Var_Secret=$3
Var_TenantId=$4

echo $1 >> /tmp/parameter.txt
echo $2 >> /tmp/parameter.txt
echo $3 >> /tmp/parameter.txt
echo $4 >> /tmp/parameter.txt

echo "Début installation Prérequis" >> /tmp/parameter.txt
#Installation du gestionnaire de paquets PIP (python-pip)
sudo apt-get update && sudo apt-get install -y libssl-dev libffi-dev python-dev python-pip

#Installation de unzip
sudo apt-get install unzip
echo "Fin installation Prérequis" >> /tmp/parameter.txt

#Installation AzureCLI
echo "Début installation AzureCLI" >> /tmp/parameter.txt
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
echo "Fin installation AzureCLI" >> /tmp/parameter.txt

#Installation Terraform (https://www.terraform.io/downloads.html)
echo "Début installation Terraform" >> /tmp/parameter.txt
wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
unzip terraform_0.12.24_linux_amd64.zip
sudo mv terraform /usr/local/bin/
rm terraform_0.12.24_linux_amd64.zip

#Check installation Terraform
echo "Version Terraform installée :" >> /tmp/parameter.txt
terraform --version >> /tmp/parameter.txt
echo "Fin installation Terraform" >> /tmp/parameter.txt

#Installation des packages Ansible avec les modules Azure
echo "Début installation Ansible" >> /tmp/parameter.txt
sudo pip install ansible[azure]

#Check installation Ansible
echo "Version Ansible installée :" >> /tmp/parameter.txt
ansible --version >> /tmp/parameter.txt
echo "Fin installation Ansible" >> /tmp/parameter.txt

echo "Début installation SPN" >> /tmp/parameter.txt
# Créer un service principal pour manager les ressources Azures
var_spn=$(az ad sp create-for-rbac --name saphana_spn)
var_sp_appid=${var_spn:14:36}
var_sp_secret=${var_spn:132:36}
var_sp_tenantid=${var_spn:184:36}
#Création des variables d'environnement
echo "# configure service principal for Ansible" >> /tmp/set-sp.sh
echo "export AZURE_SUBSCRIPTION_ID='"$Var_SubscriptionId"'" >> /tmp/set-sp.sh
echo "export AZURE_CLIENT_ID='"$var_sp_appid"'" >> /tmp/set-sp.sh
echo "export AZURE_SECRET='"$var_sp_secret"'" >> /tmp/set-sp.sh
echo "export AZURE_TENANT='"$var_sp_tenantid"'" >> /tmp/set-sp.sh
echo "# configure service principal for Terraform" >> /tmp/set-sp.sh
echo "export ARM_SUBSCRIPTION_ID='"$Var_SubscriptionId"'" >> /tmp/set-sp.sh
echo "export ARM_CLIENT_ID='"$var_sp_appid"'" >> /tmp/set-sp.sh
echo "export ARM_CLIENT_SECRET='"$var_sp_secret"'" >> /tmp/set-sp.sh
echo "export ARM_TENANT_ID='"$var_sp_tenantid"'" >> /tmp/set-sp.sh
# Application des commandes d'export
source /tmp/set-sp.sh
echo "Fin installation SPN" >> /tmp/parameter.txt

# Création de la clé SSH
echo "Début installation clé SSH" >> /tmp/parameter.txt
ssh-keygen -o -f ~/.ssh/id_rsa -N ''
echo "Fin installation clé SSH" >> /tmp/parameter.txt

echo "Début Copie Github" >> /tmp/parameter.txt
# Copie du Github
git clone https://github.com/wkdang/sap-hana.git
echo "Fin Copie Github" >> /tmp/parameter.txt

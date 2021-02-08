# IC3000-terraform

## Introduction

## Prequesites
1. Storage account to create container.
Can be created with azure CLI: az storage account create --resource-group IC3000 --name ic3000 --sku Standard_LRS --encryption-services blob
2. Storage account container to store terraform state.
az storage container create --name tfstate --account-name ic3000 --account-key {account_key}
3. Environment variable ARM_ACCESS_KEY which stores the storage account key
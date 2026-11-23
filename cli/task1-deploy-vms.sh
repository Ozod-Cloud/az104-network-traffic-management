#!/bin/bash
set -e

RG=az104-rg6
LOCATION=eastus
TEMPLATE=templates/az104-06-vms-template.json
PARAMS=templates/az104-06-vms-parameters.json

read -s -p "Admin password (12+ chars): " ADMIN_PASS
echo

# Lab step 6: Standard_D2s_v5 -> Standard_D2s_v3 (template + parameters)
sed -i 's/Standard_D2s_v5/Standard_D2s_v3/g' $TEMPLATE $PARAMS
grep -n "Standard_D2s" $TEMPLATE $PARAMS

az group create --name $RG --location $LOCATION -o table

az deployment group create \
--resource-group $RG \
--name task1-vms \
--template-file $TEMPLATE \
--parameters @$PARAMS \
--parameters adminPassword="$ADMIN_PASS" vmSize=Standard_D2s_v3 \
-o table

az vm list -g $RG -d --query "[].{Name:name, Size:hardwareProfile.vmSize, PrivateIP:privateIps, State:powerState}" -o table
az network vnet subnet list -g $RG --vnet-name az104-06-vnet1 --query "[].{Name:name, Prefix:addressPrefix}" -o table

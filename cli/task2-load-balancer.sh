#!/bin/bash
set -e

RG=az104-rg6
LOCATION=eastus
LB=az104-lb
PIP=az104-lbpip
FE=az104-fe
BE=az104-be
PROBE=az104-hp
RULE=az104-lbrule

# 1. Public IP (Standard, Static, Regional)
az network public-ip create -g $RG -n $PIP --sku Standard --allocation-method Static --location $LOCATION -o table

# 2. Load Balancer + frontend + backend pool
az network lb create -g $RG -n $LB --sku Standard \
--public-ip-address $PIP --frontend-ip-name $FE \
--backend-pool-name $BE --location $LOCATION -o table

# 3. vm0 va vm1 NIC'larini backend pool'ga qo'shish
for i in 0 1; do
NIC=az104-06-nic$i
IPCFG=$(az network nic ip-config list -g $RG --nic-name $NIC --query "[0].name" -o tsv)
az network nic ip-config address-pool add -g $RG --nic-name $NIC \
--ip-config-name $IPCFG --lb-name $LB --address-pool $BE -o none
echo "$NIC added to $BE"
done

# 4. Health probe
az network lb probe create -g $RG --lb-name $LB -n $PROBE \
--protocol Tcp --port 80 --interval 5 -o table

# 5. Load balancing rule
az network lb rule create -g $RG --lb-name $LB -n $RULE \
--protocol Tcp --frontend-port 80 --backend-port 80 \
--frontend-ip-name $FE --backend-pool-name $BE --probe-name $PROBE \
--idle-timeout 4 --enable-tcp-reset false --floating-ip false \
--disable-outbound-snat true -o table

# 6. Public IP manzili
LB_IP=$(az network public-ip show -g $RG -n $PIP --query ipAddress -o tsv)
echo "Load Balancer IP: $LB_IP"
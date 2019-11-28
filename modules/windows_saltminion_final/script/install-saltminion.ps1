Param(
   [Parameter(Mandatory=$True,Position=1)]
   [string]$SALTMINION_NAME ,
  
   [Parameter(Mandatory=$True,Position=2)]
   [string]$SALTMASTER_PRIVATE_DNS_NAME 
)
 
wget -O bootstrap-salt.ps1 https://raw.githubusercontent.com/saltstack/salt-bootstrap/develop/bootstrap-salt.ps1
.\bootstrap-salt.ps1 -minion $SALTMINION_NAME -master $SALTMASTER_PRIVATE_DNS_NAME
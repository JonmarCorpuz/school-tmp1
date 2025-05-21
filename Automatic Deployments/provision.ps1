# Set static IP
$adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress "192.168.56.10" -PrefixLength 24 -DefaultGateway "192.168.56.1"
Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses "127.0.0.1"

# Install roles
Install-WindowsFeature -Name AD-Domain-Services, DNS, DHCP -IncludeManagementTools

# Create domain
$securePass = ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force
Install-ADDSForest `
    -DomainName "victim.local" `
    -SafeModeAdministratorPassword $securePass `
    -DomainNetbiosName "VICTIM" `
    -InstallDns `
    -Force:$true

# Wait for reboot and domain controller promotion
# DHCP setup will be completed at startup using scheduled task

$script = @'
netsh dhcp add securitygroups
Restart-Service dhcpserver
Add-DhcpServerInDC -DnsName "corp.local" -IPAddress "192.168.56.10"
netsh dhcp server \\127.0.0.1 add scope 192.168.56.0 255.255.255.0 "Victim LAN"
netsh dhcp server \\127.0.0.1 scope 192.168.56.0 set optionvalue 3 IPADDRESS 192.168.56.1
netsh dhcp server \\127.0.0.1 scope 192.168.56.0 set optionvalue 6 IPADDRESS 192.168.56.10
'@

Set-Content -Path "C:\dhcp-setup.ps1" -Value $script
Register-ScheduledTask `
  -Action (New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "C:\dhcp-setup.ps1") `
  -Trigger (New-ScheduledTaskTrigger -AtStartup) `
  -TaskName "ConfigureDHCP" `
  -RunLevel Highest `
  -User "SYSTEM"

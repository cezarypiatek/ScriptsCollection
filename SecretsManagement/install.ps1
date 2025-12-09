# Install modules (only once)
Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore -Force

# Register a local vault backed by SecretStore
Register-SecretVault -Name LocalSecrets -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault -Confirm:$false

# Configure SecretStore so it does NOT require a password
$password = $(ConvertTo-SecureString -String "MySecret" -AsPlainText -Force)
Set-SecretStoreConfiguration -Authentication None -Interaction None -Confirm:$false -Password $password
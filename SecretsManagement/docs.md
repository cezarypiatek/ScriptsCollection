Managing secrets in scripts often gets messy—especially when you need a solution that works on **Windows, macOS, and Linux** without prompting for an additional password. Thankfully, PowerShell provides a clean, built-in way to do this using **SecretManagement** and **SecretStore**.

## Why This Approach?

* **Cross-platform**: Works anywhere PowerShell 7+ runs.
* **Simple API**: `Set-Secret` and `Get-Secret`.
* **No master password prompts**: Ideal for local development, automation, and CI pipelines.

## One-Time Setup

Install the modules and configure the store:

```powershell
Install-Module Microsoft.PowerShell.SecretManagement, Microsoft.PowerShell.SecretStore -Scope CurrentUser

Register-SecretVault -Name LocalSecrets -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

Set-SecretStoreConfiguration -Authentication None -Interaction None -Confirm:$false
```

This configures an encrypted, user-profile-bound vault that **does not require an additional password**.

## Storing Secrets

```powershell
Set-Secret -Name 'ApiToken' -Secret 'super-secret'
```

or credentials:

```powershell
Set-Secret -Name 'ServiceCred' -Secret (Get-Credential)
```

## Retrieving Secrets (No Prompts)

```powershell
$token = Get-Secret 'ApiToken'
$cred  = Get-Secret 'ServiceCred'
```

Perfect for scripts, scheduled jobs, or containerized environments—no interruptions.

## When You Need More Security

You can later switch the vault to require a password or move to Azure Key Vault or HashiCorp Vault without changing your scripts. SecretManagement gives you that flexibility.

---

**In short:** If you want a clean, cross-platform way to store and retrieve secrets in PowerShell without extra passwords, SecretManagement + SecretStore (with `Authentication=None`) is the most practical solution today.

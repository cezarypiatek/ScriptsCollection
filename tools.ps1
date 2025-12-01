<#
.SYNOPSIS
    Collection of MCP tool cmdlets for general system operations.

.DESCRIPTION
    This script contains cmdlets that are exposed as MCP tools.
    Each cmdlet should have proper documentation for automatic tool schema generation.
#>

function Get-DateInfo {
    <#
    .SYNOPSIS
        Returns date and timezone information.
    
    .DESCRIPTION
        Gets the current date/time in ISO 8601 format and the current timezone identifier.
    
    .EXAMPLE
        Get-DateInfo
        Returns the current date and timezone.
    
    .OUTPUTS
        Hashtable with date and timezone properties.
    #>
    [CmdletBinding()]
    param()
    
    return @{
        date = (Get-Date).ToString("o")
        timezone = (Get-TimeZone).Id
    }
}

function Add-Numbers {
    <#
    .SYNOPSIS
        Adds two numbers together.
    
    .DESCRIPTION
        Takes two numeric values and returns their sum.
    
    .PARAMETER a
        The first number to add.
    
    .PARAMETER b
        The second number to add.
    
    .EXAMPLE
        Add-Numbers -a 5 -b 3
        Returns 8.
    
    .OUTPUTS
        Hashtable with result property containing the sum.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$a,
        
        [Parameter(Mandatory = $true)]
        [double]$b
    )
    
    return @{
        result = $a + $b
    }
}

function Get-RunningServices {
    <#
    .SYNOPSIS
        Returns a list of running Windows services.
    
    .DESCRIPTION
        Retrieves all Windows services that are currently in the Running state.
    
    .EXAMPLE
        Get-RunningServices
        Returns all running services with their names and display names.
    
    .OUTPUTS
        Array of hashtables with Name, DisplayName, and Status properties.
    #>
    [CmdletBinding()]
    param()
    
    Get-Service | Where-Object { $_.Status -eq "Running" } | Select-Object Name, DisplayName, Status | ForEach-Object {
        @{
            Name = $_.Name
            DisplayName = $_.DisplayName
            Status = $_.Status.ToString()
        }
    }
}

function Get-RunningProcesses {
    <#
    .SYNOPSIS
        Returns a list of running processes.
    
    .DESCRIPTION
        Retrieves all currently running processes with their ID, name, CPU usage, and path.
    
    .EXAMPLE
        Get-RunningProcesses
        Returns all running processes.
    
    .OUTPUTS
        Array of hashtables with Id, ProcessName, CPU, and Path properties.
    #>
    [CmdletBinding()]
    param()
    
    Get-Process | Select-Object Id, ProcessName, CPU, Path | ForEach-Object {
        @{
            Id = $_.Id
            ProcessName = $_.ProcessName
            CPU = $_.CPU
            Path = $_.Path
        }
    }
}

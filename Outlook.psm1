function Get-OutlookEmails {
    <#
    .SYNOPSIS
        Fetches emails from Outlook for a given time period.
    
    .DESCRIPTION
        Retrieves emails from the Outlook Inbox folder and optionally the Archive folder 
        within a specified date range. Returns sender, title (subject), and text content for each email.
    
    .PARAMETER StartDate
        The start date of the time period to fetch emails from.
    
    .PARAMETER EndDate
        The end date of the time period to fetch emails from. Defaults to current date/time.
    
    .PARAMETER FolderName
        The name of the mail folder to search. Defaults to "Inbox".
    
    .PARAMETER IncludeArchive
        If specified, also searches the Archive folder for emails.
    
    .PARAMETER Sender
        Optional filter to match sender name or email address (supports regex).
    
    .EXAMPLE
        Get-OutlookEmails -StartDate (Get-Date).AddDays(-7)
        # Gets emails from the last 7 days
    
    .EXAMPLE
        Get-OutlookEmails -StartDate "2025-11-01" -EndDate "2025-11-15"
        # Gets emails between November 1st and 15th, 2025
    
    .EXAMPLE
        Get-OutlookEmails -StartDate (Get-Date).AddDays(-90) -IncludeArchive
        # Gets emails from the last 90 days including archived emails
    
    .OUTPUTS
        PSCustomObject with SenderName, SenderAddress, Title, TextContent, and ReceivedTime properties
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate = (Get-Date),
        
        [Parameter(Mandatory = $false)]
        [string]$FolderName = "Inbox",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeArchive,
        
        [Parameter(Mandatory = $false)]
        [string]$Sender
    )
    
    # Helper function to process emails from a folder
    function Get-EmailsFromFolder {
        param(
            $Folder,
            [DateTime]$Start,
            [DateTime]$End,
            [System.Collections.ArrayList]$ResultList
        )
        
        $items = $Folder.Items
        $items.Sort("[ReceivedTime]", $true)  # Sort descending (newest first)
        $items.IncludeRecurrences = $false
        
        foreach ($email in $items) {
            try {
                # Only process mail items (not meeting requests, etc.)
                if ($email.Class -eq 43) {  # olMail = 43
                    $receivedTime = $email.ReceivedTime
                    
                    # Skip if outside date range
                    if ($receivedTime -lt $Start) {
                        # Since sorted descending, if we're past the start date, we can stop
                        break
                    }
                    
                    if ($receivedTime -le $End) {
                        [void]$ResultList.Add([PSCustomObject]@{
                            SenderName    = $email.SenderName
                            SenderAddress = $email.SenderEmailAddress
                            Title         = $email.Subject
                            TextContent   = $email.Body
                            ReceivedTime  = $receivedTime
                            Folder        = $Folder.Name
                        })
                    }
                }
            }
            catch {
                # Skip items that can't be accessed
                Write-Verbose "Skipped an item: $_"
            }
        }
        
        if ($items) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($items) | Out-Null }
    }
    
    try {
        # Create Outlook COM object
        $outlook = New-Object -ComObject Outlook.Application
        $namespace = $outlook.GetNamespace("MAPI")
        
        # Get the Inbox folder (olFolderInbox = 6)
        $inbox = $namespace.GetDefaultFolder(6)
        
        # If a different folder is specified, try to find it
        if ($FolderName -ne "Inbox") {
            $inbox = $inbox.Folders | Where-Object { $_.Name -eq $FolderName }
            if (-not $inbox) {
                throw "Folder '$FolderName' not found"
            }
        }
        
        # Process and return email data
        $results = [System.Collections.ArrayList]::new()
        
        # Get emails from primary folder
        Write-Verbose "Searching in $($inbox.Name)..."
        Get-EmailsFromFolder -Folder $inbox -Start $StartDate -End $EndDate -ResultList $results
        
        # Get emails from Archive if requested
        if ($IncludeArchive) {
            try {
                # Try to get Archive folder - it's a top-level folder in the store
                $archiveFolder = $null
                
                # Search through all stores for Archive folder
                foreach ($store in $namespace.Stores) {
                    try {
                        $rootFolder = $store.GetRootFolder()
                        foreach ($folder in $rootFolder.Folders) {
                            if ($folder.Name -match "Archive|Archiv") {
                                $archiveFolder = $folder
                                Write-Verbose "Found archive folder: $($folder.Name) in $($store.DisplayName)"
                                Get-EmailsFromFolder -Folder $archiveFolder -Start $StartDate -End $EndDate -ResultList $results
                            }
                        }
                    }
                    catch {
                        Write-Verbose "Could not access store: $($store.DisplayName)"
                    }
                }
                
                if (-not $archiveFolder) {
                    Write-Warning "Archive folder not found"
                }
            }
            catch {
                Write-Warning "Could not access Archive folder: $_"
            }
        }
        
        $results = $results | Sort-Object ReceivedTime -Descending
        
        # Filter by sender if specified
        if (-not [string]::IsNullOrEmpty($Sender)) {
            $results = $results | Where-Object { 
                $_.SenderName -match $Sender -or $_.SenderAddress -match $Sender 
            }
        }
        
        return $results
    }
    catch {
        Write-Error "Failed to fetch Outlook emails: $_"
        throw
    }
    finally {
        # Clean up COM objects
        if ($inbox) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($inbox) | Out-Null }
        if ($namespace) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($namespace) | Out-Null }
        if ($outlook) { [System.Runtime.InteropServices.Marshal]::ReleaseComObject($outlook) | Out-Null }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

Export-ModuleMember -Function Get-OutlookEmails

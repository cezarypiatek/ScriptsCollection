param(
    $Port,
    [switch]$Kill
)

$processId = Get-NetTCPConnection -LocalPort $Port
if(-not ($processId -eq $null))
{
    $process = Get-Process -Id ($processId)
    $process
    if($Kill)
    {
        $process.OwningProcess | Stop-Process
    }
}

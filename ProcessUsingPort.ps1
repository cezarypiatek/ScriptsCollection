param(
    $Port,
    [switch]$Kill
)

$results = Get-NetTCPConnection -LocalPort $Port | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object {Get-Process -Id $_}

if(-not ($null -eq $results))
{
    $results | Format-Table -Property Id, Name, Path -AutoSize
    $results | ForEach-Object {
        
        if($Kill)
        {
            $_ | Stop-Process
        }
    }
}

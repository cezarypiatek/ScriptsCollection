param($Distribution, $PullLatest)

$image = if($Distribution -eq "Nightly")
{
    "mcr.microsoft.com/dotnet/nightly/aspire-dashboard"
}
else{
   "mcr.microsoft.com/dotnet/aspire-dashboard"
}

if($PullLatest)
{
    docker pull $image
}

docker run --rm --name AspireDashboard -p 18888:18888 -p 4317:18889 -e DOTNET_DASHBOARD_UNSECURED_ALLOW_ANONYMOUS=true $image |%{
    if($_ -match "Now listening on")
    {
        Write-Host "*******************************"
        Register-EngineEvent -SourceIdentifier Powershell.Exiting -Action { 
            Write-Host "Stoping Dashboard"
            docker stop AspireDashboard
        } | Out-Null
        Start-Process "http://localhost:18888"
    }
    $_
}
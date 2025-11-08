param($Distribution, $PullLatest, $WebPort = 18888, $OtLPort = 4317, $Tag="latest")

$image = if($Distribution -eq "Nightly")
{
    "mcr.microsoft.com/dotnet/nightly/aspire-dashboard:$Tag"
}
else{
   "mcr.microsoft.com/dotnet/aspire-dashboard:$Tag"
}

if($PullLatest)
{
    docker pull $image
}

docker run --rm --name AspireDashboard -p  $WebPort`:18888 -p $OtLPort`:18889 -e DOTNET_DASHBOARD_UNSECURED_ALLOW_ANONYMOUS=true $image |%{
    if($_ -match "Now listening on")
    {
        Write-Host "*******************************"
        Register-EngineEvent -SourceIdentifier Powershell.Exiting -Action { 
            Write-Host "Stoping Dashboard"
            docker stop AspireDashboard
        } | Out-Null
        Start-Process "http://localhost:$WebPort"
    }
    $_
}
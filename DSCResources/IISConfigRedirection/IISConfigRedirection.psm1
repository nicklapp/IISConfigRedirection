function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure
    )

    $RedirectionConfig = [xml](Get-Content "$env:windir\System32\inetsrv\config\redirection.config")
    $Enabled = $RedirectionConfig.configuration.configurationRedirection.enabled
    $Path = $RedirectionConfig.configuration.configurationRedirection.path

    Return @{
        Enabled = $Enabled
        Path = $Path
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $Path
    )

    [System.Reflection.Assembly]::LoadFrom("$env:windir\System32\inetsrv\Microsoft.Web.Administration.dll")

    $ServerManager =  New-Object Microsoft.Web.Administration.ServerManager
    $Config = $ServerManager.GetRedirectionConfiguration()
    $RedirectionSection = $Config.GetSection("configurationRedirection")

    if($Ensure -eq "Present") {
        Write-Verbose "Enabling IIS Redirection"
        Write-Verbose "Setting IIS Redirection Path: $Path"
        $RedirectionSection.Attributes["enabled"].Value = "true"
        $RedirectionSection.Attributes["path"].Value = $Path
    }
    else {
        Write-Verbose "Removing IIS Redirection"
        $RedirectionSection.Attributes["enabled"].Value = $Null
        $RedirectionSection.Attributes["path"].Value = $Null
    }

    $ServerManager.CommitChanges()

    iisreset.exe
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure,

        [System.String]
        $Path
    )

    $RedirectionConfig = [xml](Get-Content "$env:windir\System32\inetsrv\config\redirection.config")
    $CurrentState = $RedirectionConfig.configuration.configurationRedirection.enabled
    $CurrentPath = $RedirectionConfig.configuration.configurationRedirection.path

    Write-Verbose "Current IIS Redirection Enabled State: $CurrentState"
    Write-Verbose "Current IIS Redirection Path: $CurrentPath"
    
    if($Ensure -eq "Present") {
        if($CurrentState -eq "true" -and $CurrentPath -eq $Destination) {
            Return $True
        }
        else {
            Return $False
        }
    }
    else {
        if($CurrentState -eq $Null -and $CurrentPath -eq $Null) {
            Return $True
        }
        else {
            Return $False
        }
    }
}


Export-ModuleMember -Function *-TargetResource


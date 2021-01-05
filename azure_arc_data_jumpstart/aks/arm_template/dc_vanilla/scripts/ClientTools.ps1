param (
    [string]$servicePrincipalClientId,
    [string]$servicePrincipalClientSecret,
    [string]$adminUsername,
    [string]$tenantId,
    [string]$clusterName,
    [string]$resourceGroup,
    [string]$AZDATA_USERNAME,
    [string]$AZDATA_PASSWORD,
    [string]$ACCEPT_EULA,
    [string]$REGISTRY_USERNAME,
    [string]$REGISTRY_PASSWORD,
    [string]$ARC_DC_NAME,
    [string]$ARC_DC_SUBSCRIPTION,
    [string]$ARC_DC_REGION,
    [string]$chocolateyAppList,
    [string]$DOCKER_REGISTRY,
    [string]$DOCKER_REPOSITORY,
    [string]$DOCKER_TAG
)

[System.Environment]::SetEnvironmentVariable('servicePrincipalClientId', $servicePrincipalClientId,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('servicePrincipalClientSecret', $servicePrincipalClientSecret,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('adminUsername', $adminUsername,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('tenantId', $tenantId,[System.EnvironmentVariableTarget]::Machine)

[System.Environment]::SetEnvironmentVariable('SPN_CLIENT_ID', $servicePrincipalClientId,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('SPN_CLIENT_SECRET', $servicePrincipalClientSecret,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('SPN_TENANT_ID', $tenantId,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('SPN_AUTHORITY', 'https://login.microsoftonline.com', [System.EnvironmentVariableTarget]::Machine)


[System.Environment]::SetEnvironmentVariable('clusterName', $clusterName,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('resourceGroup', $resourceGroup,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AZDATA_USERNAME', $AZDATA_USERNAME,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('AZDATA_PASSWORD', $AZDATA_PASSWORD,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('ACCEPT_EULA', $ACCEPT_EULA,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('REGISTRY_USERNAME', $REGISTRY_USERNAME,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('REGISTRY_PASSWORD', $REGISTRY_PASSWORD,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('ARC_DC_NAME', $ARC_DC_NAME,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('ARC_DC_SUBSCRIPTION', $ARC_DC_SUBSCRIPTION,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('ARC_DC_REGION', $ARC_DC_REGION,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('DOCKER_REGISTRY', $DOCKER_REGISTRY,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('DOCKER_REPOSITORY', $DOCKER_REPOSITORY,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('DOCKER_TAG', $DOCKER_TAG,[System.EnvironmentVariableTarget]::Machine)

# Installing tools
New-Item -Path "C:\" -Name "tmp" -ItemType "directory" -Force
workflow ClientTools_01
        {
            $chocolateyAppList = 'azure-cli,az.powershell,kubernetes-cli,vcredist140'
            #Run commands in parallel.
            Parallel 
                {
                    InlineScript {
                        param (
                            [string]$chocolateyAppList
                        )
                        if ([string]::IsNullOrWhiteSpace($using:chocolateyAppList) -eq $false)
                        {
                            try{
                                choco config get cacheLocation
                            }catch{
                                Write-Output "Chocolatey not detected, trying to install now"
                                iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
                            }
                        }
                        if ([string]::IsNullOrWhiteSpace($using:chocolateyAppList) -eq $false){   
                            Write-Host "Chocolatey Apps Specified"  
                            
                            $appsToInstall = $using:chocolateyAppList -split "," | foreach { "$($_.Trim())" }
                        
                            foreach ($app in $appsToInstall)
                            {
                                Write-Host "Installing $app"
                                & choco install $app /y -Force| Write-Output
                            }
                        }                        
                    }
                    Invoke-WebRequest "https://azuredatastudio-update.azurewebsites.net/latest/win32-x64-archive/stable" -OutFile "C:\tmp\azuredatastudio.zip"
                    Invoke-WebRequest "https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_data_jumpstart/aks/arm_template/dc_vanilla/settings.json" -OutFile "C:\tmp\settings.json"
                    Invoke-WebRequest "https://aka.ms/azdata-msi" -OutFile "C:\tmp\AZDataCLI.msi"
                    Invoke-WebRequest "https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_data_jumpstart/aks/arm_template/dc_vanilla/scripts/DC_Cleanup.ps1" -OutFile "C:\tmp\DC_Cleanup.ps1"
                    Invoke-WebRequest "https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_data_jumpstart/aks/arm_template/dc_vanilla/scripts/DC_Deploy.ps1" -OutFile "C:\tmp\DC_Deploy.ps1"
                }
        }

#ClientTools_01 | Format-Table


        Invoke-WebRequest "https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_data_jumpstart/aks/arm_template/dc_vanilla/settings.json" -OutFile "C:\tmp\settings.json"
        Invoke-WebRequest "https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_data_jumpstart/aks/arm_template/dc_vanilla/scripts/DC_Cleanup.ps1" -OutFile "C:\tmp\DC_Cleanup.ps1"
        Invoke-WebRequest "https://raw.githubusercontent.com/microsoft/azure_arc/main/azure_arc_data_jumpstart/aks/arm_template/dc_vanilla/scripts/DC_Deploy.ps1" -OutFile "C:\tmp\DC_Deploy.ps1"
               

workflow ClientTools_02
        {
            #Run commands in parallel.
            Parallel
            {
                InlineScript {
                    Expand-Archive C:\tmp\azuredatastudio.zip -DestinationPath 'C:\Program Files\Azure Data Studio'
                    Start-Process msiexec.exe -Wait -ArgumentList '/I C:\tmp\AZDataCLI.msi /quiet'
                }
            }
        }
        
#ClientTools_02 | Format-Table 

New-Item -path alias:kubectl -value 'C:\ProgramData\chocolatey\lib\kubernetes-cli\tools\kubernetes\client\bin\kubectl.exe'
New-Item -path alias:azdata -value 'C:\Program Files (x86)\Microsoft SDKs\Azdata\CLI\wbin\azdata.cmd'

#Enable Autologon
$AutoLogonRegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoAdminLogon" -Value "1" -type String 
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultUsername" -Value "$($env:ComputerName)\$($adminUsername)" -type String  
Set-ItemProperty -Path $AutoLogonRegPath -Name "DefaultPassword" -Value "ArcPassword123!!" -type String
Set-ItemProperty -Path $AutoLogonRegPath -Name "AutoLogonCount" -Value "1" -type DWord

# Creating PowerShell Logon Script
$LogonScript = @'
Start-Transcript -Path C:\tmp\LogonScript.log



$azurePassword = ConvertTo-SecureString $env:servicePrincipalClientSecret -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($($env:servicePrincipalClientId) , $($azurePassword))
Connect-AzAccount -Credential $psCred -TenantId $($env:tenantId) -ServicePrincipal
Import-AzAksCredential -ResourceGroupName $($env:resourceGroup) -Name $($env:clusterName) -Force

kubectl get nodes
azdata --version


# Deploying Azure Arc Data Controller
start PowerShell {for (0 -lt 1) {kubectl get pod -n $env:ARC_DC_NAME; sleep 5; clear }}
azdata arc dc config init --source azure-arc-aks-premium-storage --path "C:\tmp\custom"
if(($env:DOCKER_REGISTRY -ne $NULL) -or ($env:DOCKER_REGISTRY -ne ""))
{
    azdata arc dc config replace --path "C:\tmp\custom\control.json" --json-values "spec.docker.registry=$env:DOCKER_REGISTRY"
}
if(($($env:DOCKER_REPOSITORY) -ne $NULL) -or ($($env:DOCKER_REPOSITORY) -ne ""))
{
    azdata arc dc config replace --path "C:\tmp\custom\control.json" --json-values "spec.docker.repository=$env:DOCKER_REPOSITORY"
}
if(($($env:DOCKER_TAG) -ne $NULL) -or ($($env:DOCKER_TAG) -ne ""))
{
    azdata arc dc config replace --path "C:\tmp\custom\control.json" --json-values "spec.docker.imageTag=$env:DOCKER_TAG"
}

azdata arc dc create --namespace $($env:ARC_DC_NAME) --name $($env:ARC_DC_NAME) --subscription $($env:ARC_DC_SUBSCRIPTION) --resource-group $($env:resourceGroup) --location $($env:ARC_DC_REGION) --connectivity-mode direct --path "C:\tmp\custom"

Unregister-ScheduledTask -TaskName "LogonScript" -Confirm:$false

Stop-Transcript

Stop-Process -name powershell -Force
'@ > C:\tmp\LogonScript.ps1


$User= "$($env:ComputerName)\$($adminUsername)"
# Creating LogonScript Windows Scheduled Task
$Trigger = New-ScheduledTaskTrigger -AtLogOn
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument 'C:\tmp\LogonScript.ps1'
Register-ScheduledTask -TaskName "LogonScript" -Trigger $Trigger -User $User -Action $Action -RunLevel "Highest" -Force

Restart-Computer -Force
# Disabling Windows Server Manager Scheduled Task
#Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask

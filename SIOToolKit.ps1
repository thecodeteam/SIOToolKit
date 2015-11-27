[CmdletBinding()]
Param(
    [System.Net.IPAddress]$mdm_ip1,
    [System.Net.IPAddress]$mdm_ip2,
    $UserName,
    $Password
)
function test-scli
{
[CmdletBinding()]
Param()
write-verbose "checking if SCLI is installed"
try
    {
    $scliversion = scli --version | out-null
    }
catch [System.Management.Automation.CommandNotFoundException] 
    {
    # "Base Exception" 
    Write-verbose "Could not find SCLI, trying modulepath"
    if (!(Test-Path $PSScriptRoot\cli.exe))
        {
        Write-warning "Neither SCLI installation nor cli.exe in Module Path are found. 
if this is not an mdm, please copy cli.exe from ScaleIO Windows installation to $PSScriptRoot
it can be extracted uing 7zip from the EMC-ScaleIO-mdm-1.32-xxx.msi"
        pause
        break 
        }
    else 
        {
        Write-Verbose "setting alias for scli"
        Set-Alias -Name scli -Value "$PSScriptRoot\cli.exe" -Description "ScaleIO SCLI" -Scope Global
        $scliversion= scli --version
        }
         
    }
$Global:scliversion = $scliversion
Write-Verbose "Running SCLI $scliversion"


}




function Connect-SIOmdm
{
[CmdletBinding()]
Param()
Write-Verbose "Connecting to MDM $Global:mdm"


#decrypting password:

$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($siopassword)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
 

$ConnectMDM = scli --mdm_ip $mdm --login --username $siousername --password $password 2>&1 | out-null
if ($LASTEXITCODE -ne 0)
    {
    switch ($LASTEXITCODE)
        {
        "1"
        {
        Write-Error "Error connecting to MDM, Please make sure to specify right IP Addresses"
        }
        "7"
        {
        Write-Error "Error connecting to MDM, check user/password"
        }
        default
        {Write-Error "Exit Code $LASTEXITCODE"}
        }
        
    [bool]$Global:SIOConnected = $false
    break
    }
else
    {
    $ConnectMDM
    [bool]$Global:SIOConnected = $True
    }

}
    


test-scli #-Verbose


# Connect-SIOmdm -Verbose



if ($Global:SIOConnected)
    {
    [validateSet('Y','n')]$reconnectSIO = Read-Host -Prompt "Already Scoped to $Global:mdm, select new MDM (Y/N)"
    }



If (!$Global:SIOConnected -or $reconnectSIO -match "Y")
    {
    if ($mdm_ip1)
        {
        [System.Net.IPAddress]$Global:mdmip1 = $mdm_ip1
        }
    else
        {
        [System.Net.IPAddress]$Global:mdmip1 = Read-Host -Prompt "Enter IP for Primary MDM"
        }
    if ($mdm_ip2)
        {
        [System.Net.IPAddress]$Global:mdmip2 = $mdm_ip2
        }
    else
        {
        [System.Net.IPAddress]$Global:mdmip2 = Read-Host -Prompt "Enter IP for Secondary MDM"
        }
    if ($UserName)
        {
        $Global:sioUserName = $UserName
        }
    else
        {
        $Global:sioUserName = Read-Host -Prompt "Enter MDM Username"
        }
    if ($password)
        {
        $Global:sioPassword = $Password | ConvertTo-SecureString -AsPlainText -Force
        }
    else
        {
        $Global:sioPassword = Read-Host -Prompt "Enter MDM Password" -AsSecureString
        }
    $Global:mdm = "$Global:mdmip1,$Global:mdmip2"
    }


try
    {
    Connect-SIOmdm -Verbose -ErrorAction Stop
    }
catch
    {
    Write-Warning "Could not connect to MDM with given Parameters. Wrong Password ?"
    break
    }


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
    exit
    }
else
    {
    $ConnectMDM
    [bool]$Global:SIOConnected = $True
    }

}
    
if ($Global:SIOConnected)
    {
    [validateSet('Y','n')]$reconnectSIO = Read-Host -Prompt "reconnect MDM (Y/N): "
    }

If (!$Global:SIOConnected -or $reconnectSIO -match "Y")
    {
    [System.Net.IPAddress]$Global:mdmip1 = Read-Host -Prompt "Enter IP for MDM1: "
    [System.Net.IPAddress]$Global:mdmip2 = Read-Host -Prompt "Enter IP for MDM2: "
    $Global:sioUserName = Read-Host -Prompt "Enter MDM Username: "
    $Global:sioPassword = Read-Host -Prompt "Enter MDM Password: " -AsSecureString
    $Global:mdm = "$mdmip1,$mdmip2"
    }
#>


Connect-SIOmdm -Verbose
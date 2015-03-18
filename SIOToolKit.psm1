$NameTag = "Name: "
$PoolPattern = "Storage Pool "
$PDPattern = "Protection Domain "
$PrimaryTag ="Primary IP: "
$SecondaryTag = "Secondary IP: "
$TieTag = "Tie-Breaker IP: "
$MgmtTag = "Management IP: "
$Modetag = "Mode: "
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Connect-SIOmdm
{
[CmdletBinding()]
Param()
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($Global:siopassword)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
$cmdresult = scli --mdm_ip $Global:mdm --login --username $Global:siousername --password $password 2> $null
if ($LASTEXITCODE -ne 0)
    {
    Write-Error "Error connecting to MDM"
    exit
    }
Else 
    {
    Write-Output $cmdresult
    }


}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Get-yesno
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    Param
    (
$title = "Delete Files",
$message = "Do you want to delete the remaining files in the folder?",
$Yestext = "Yestext",
$Notext = "notext"
    )
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","$Yestext"
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","$Notext"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($no, $yes)
$result = $host.ui.PromptForChoice($title, $message, $options, 0)
return ($result)
}


function convert-perfdata
{
param (
$strPerfdata
)


            $strperfdata = $strperfdata.Replace(")","")
            $strperfdata = $strperfdata.split("(")
            $strperfdata = $strperfdata[-1]
            [System.Double]$Mathperfdata = Invoke-Expression "$strperfdata" 2>%1 
            if ($Mathperfdata)
                {

                $Mathperfdata
                }

}


function convert-capacity
{
param (
$strCapacity
)


            $strCapacity = $strCapacity.Replace(")","")
            $strCapacity = $strCapacity.split("(")
            $strCapacity = $strCapacity[-1]
            [System.Double]$MathCapacity = Invoke-Expression "$strCapacity" 2>%1 
            if ($MathCapacity)
                {

                $MathCapacity/1GB
                }

}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Show-SIOStoragePools
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    Param
    (
    )

    Begin
    {
    $mdmmessage = Connect-SIOmdm
    }
    Process
    {
        $Pools = scli --query_all --mdm_ip $Global:mdm 2> $null
        foreach ($line in $Pools)
        {
        
        If ($line -match $PDPattern)
            {
            write-verbose " Found PD : $Line"
                    $PD = $Line.Replace("$PDPattern","")
                    $PD = $PD.Replace("(Id: ","")
                    $PD = $PD.Replace(")","")
                    $PD = $PD.SPlit(' ')
                    $PDname = $PD[0]
                    $PDID = $PD[1]


            }
            If ($line -match $PoolPattern)
                {
                Write-Verbose "Found Pool $line"
                    $Pool = $Line.Replace("$PoolPattern","")
                    $Pool = $Pool.Replace("(Id: ","")
                    $Pool = $Pool.Replace(")","")
                    $pool = $pool.SPlit(' ')
                    $poolname = $pool[0]
                    $poolID = $pool[1]
                    Write-Verbose "Found Pool $poolname with ID $poolID"
                    $object = New-Object -TypeName psobject
		            $object | Add-Member -MemberType NoteProperty -Name PoolName -Value $poolname
		            $object | Add-Member -MemberType NoteProperty -Name PoolID -Value $poolID
		            $object | Add-Member -MemberType NoteProperty -Name ProtectionDomainName -Value $PDname
		            $object | Add-Member -MemberType NoteProperty -Name ProtectionDomainID -Value $PDID
                    Write-Output $object
                }


        }
    }
    End
    {
    }

}



<#
.Synopsis
Short description
.DESCRIPTION
Long description
.EXAMPLE
Example of how to use this cmdlet
.EXAMPLE
Another example of how to use this cmdlet
.INPUTS
Inputs to this cmdlet (if any)
.OUTPUTS
Output from this cmdlet (if any)
.NOTES
General notes
.COMPONENT
The component this cmdlet belongs to
.ROLE
The role this cmdlet belongs to
.FUNCTIONALITY
The functionality that best describes this cmdlet
#>
function Get-SIOVolumePerf
{
[CmdletBinding(DefaultParameterSetName='1',
SupportsShouldProcess=$true,
PositionalBinding=$false,
HelpUri = 'http://labbuildr.com/',
ConfirmImpact='Medium')]
Param
(

[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")][Alias("SDCVOLUME_ID_LIST")]$VolumeID,
# Specify the SIO Volume Name  
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')]
[ValidateNotNull()][ValidateNotNullOrEmpty()][Alias("Name")]$VolumeName


 )
Begin
    {
    $mdmmessage = Connect-SIOmdm



[string]$Props = "USER_DATA_READ_BWC
USER_DATA_WRITE_BWC"
$Props = $Props.Replace("`n",",")
$Props = $Props.Replace("`r","")

}



Process
{
switch ($PsCmdlet.ParameterSetName)
    {
        "1"
        {
        $private:Volumeprop = Get-mdmobjects -props "$Props" -objectid $VolumeID -objecttype VOLUME #-Verbose
        }
        "2"
        {
        $VolumeID = (Get-SIOVolume -VolumeName $VolumeName).VolumeID
        if ($VolumeID)
            {
            $private:Volumeprop = Get-mdmobjects -props "$Props" -objectid $VolumeID -objecttype VOLUME #-Verbose
            }
        }
    }
            
            $ReadIOPS = ($private:Volumeprop.VOLUME_USER_DATA_READ_BWC.Split('IOPS'))[0]
            $ReadBS = ($private:Volumeprop.VOLUME_USER_DATA_READ_BWC.Split('IOPS'))[-1]
            $ReadBS = ($READBS.Split('Bytesper-second'))[0]
            $WRITEIOPS = ($private:Volumeprop.VOLUME_USER_DATA_WRITE_BWC.Split('IOPS'))[0]
            $WRITEBS = ($private:Volumeprop.VOLUME_USER_DATA_WRITE_BWC.Split('IOPS'))[-1]
            $WRITEBS = ($WRITEBS.Split('Bytesper-second'))[0]
            $object = New-Object -TypeName psobject
            $object | Add-Member -MemberType NoteProperty -Name VolumeID -Value $VOLUMEID
            $object | Add-Member -MemberType NoteProperty -Name ReadIOPS -Value $ReadIOPS
            $object | Add-Member -MemberType NoteProperty -Name READBytesSec -Value $ReadBS
            $object | Add-Member -MemberType NoteProperty -Name WriteIOPS -Value $WriteIOPS
            $object | Add-Member -MemberType NoteProperty -Name WriteBytesSec -Value $WriteBS
            <#if ([System.Double]$Capacity = convert-capacity $private:Volumeprop.VOLUME_SIZE)
                {
                $object | Add-Member -MemberType NoteProperty -Name CapacityGB -Value ([System.Double]$Capacity)
                }
            else
                {
                $object | Add-Member -MemberType NoteProperty -Name Capacity -Value $private:Volumeprop.VOLUME_SIZE
                } #>
            
            Write-Output $object
    }



End
{
}
}



<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Show-SIOcluster
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
Param
    (
    )

Begin
    {
    $mdmmessage = Connect-SIOmdm
    }
Process
    {
    $Cluster = scli --query_cluster --mdm_ip $Global:mdm 2> $null
    $object = New-Object -TypeName psobject

    #  Mode: Cluster, Cluster State: Normal, Tie-Breaker State: Connected

    $ClusterMode = $Cluster | where {$_ -match $Modetag}
    $ClusterMode = $ClusterMode.replace($Modetag,"")
    $ClusterMode = $ClusterMode.replace("Cluster State: ","")
    $ClusterMode = $ClusterMode.replace("Tie-Breaker State: ","")
    $ClusterMode = $ClusterMode.TrimStart(" ")
    $ClusterMode = $ClusterMode.Split(" ")
    $Object | Add-Member -MemberType NoteProperty -Name ClusterMode -Value $ClusterMode[0]
    $Object | Add-Member -MemberType NoteProperty -Name ClusterState -Value $ClusterMode[1]
    $Object | Add-Member -MemberType NoteProperty -Name TieBreakerState -Value $ClusterMode[2]
    $ClusterMode = $ClusterMode.Split(" ")
    $Clustername = $Cluster | where {$_ -match $NameTag}
    $Clustername = $Clustername.replace($NameTag,"")
    $Clustername = $Clustername.replace(" ","")
    $Object | Add-Member -MemberType NoteProperty -Name ClusterName -Value $Clustername
    $PrimaryIP = $Cluster | where {$_ -match $PrimaryTag}
    $PrimaryIP = $PrimaryIP.replace($PrimaryTag,"")
    $PrimaryIP = $PrimaryIP.replace(" ","")
    $Object | Add-Member -MemberType NoteProperty -Name PrimaryIP -Value $PrimaryIP
    $SecondaryIP = $Cluster | where {$_ -match $SecondaryTag}
    $SecondaryIP = $SecondaryIP.replace($SecondaryTag,"")
    $SecondaryIP = $SecondaryIP.replace(" ","")
    $Object | Add-Member -MemberType NoteProperty -Name SecondaryIP -Value $SecondaryIP
    $TieIP = $Cluster | where {$_ -match $TieTag}
    $TieIP = $TieIP.replace($TieTag,"")
    $TieIP = $TieIP.replace(" ","")
    $Object | Add-Member -MemberType NoteProperty -Name TieBreakerIP -Value $TieIP
    $MgmtIP = $Cluster | where {$_ -match $MgmtTag}
    $MgmtIP = $MgmtIP.replace($MgmtTag,"")
    $MgmtIP = $MgmtIP.replace(" ","")
    $Object | Add-Member -MemberType NoteProperty -Name ManagementIP -Value $MgmtIP
    Write-Output $object
    }

    End
    {
    }

}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Show-SIOVolumes
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    Param
    (
    )

    Begin
    {
    $mdmmessage = Connect-SIOmdm
    }
    Process
    {
        if ($pscmdlet.ShouldProcess("TarGet", "Operation"))
        {
        $Volumes = scli --query_all_volumes --mdm_ip $Global:mdm 2> $null


        foreach ($Volume in $Volumes )
            {
            # find pool in volumelist
            [bool]$Mapped = $false
            if ($Volume -match "Storage Pool")
                {
                    $currentpool = $Volume.Replace($PoolPattern,"")
                    $currentpool = $currentpool.Replace(" Name:","")
                    $currentpool = $currentpool.SPlit(' ')
                    $Currentpoolname = $currentpool[1]
                    $CurrentpoolID = $currentpool[0]
                    Write-Verbose "Found Pool $Currentpoolname with ID $CurrentpoolID"
                }
            if ($Volume -match  " Volume ID: ")
                {
                if ($Volume -match " Snapshot of ")
                    {
                    $Type = "Snapshot"
                    }
                elseif ($Volume -match " Thin-provisioned")
                    {
                    $Type = "Thin"
                    }
                If ($Volume -match " Mapped ")
                    {
                    [bool]$Mapped = $true
                    }
                $currentvolume = $Volume.Replace(" Volume ID: ","")
                $currentvolume = $currentvolume.Replace(" Name:","")
                $currentvolume = $currentvolume.Replace(" Size:","")

                $currentvolume = $currentvolume.SPlit(' ')
                $currentvolumeID = $currentvolume[0]
                $currentvolumename = $currentvolume[1]
                $currentvolumeSize = $currentvolume[2]


                Write-Verbose "Found Volume $currentvolumename with ID $currentvolumeID"

                $object = New-Object -TypeName psobject
		        $Object | Add-Member -MemberType NoteProperty -Name VolumeName -Value $currentvolumename
		        $object | Add-Member -MemberType NoteProperty -Name SizeGB -Value $currentvolumeSize
		        $object | Add-Member -MemberType NoteProperty -Name Type -Value $Type
		        $Object | Add-Member -MemberType NoteProperty -Name VolumeID -Value $currentvolumeID
		        $object | Add-Member -MemberType NoteProperty -Name Pool -Value $Currentpoolname
		        $object | Add-Member -MemberType NoteProperty -Name PoolID -Value $CurrentpoolID
                $object | Add-Member -MemberType NoteProperty -Name Mapped -Value $Mapped
                Write-Output $object
                }


            }


        }
    }
    End
    {
    }

}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Get-SIOVolume
{
    [CmdletBinding(DefaultParameterSetName='1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    # [OutputType([String])]
    Param
    (
    # Specify the SIO Volume ID  
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   ParameterSetName='1')]
        [validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]
        [Alias("SDCVOLUME_ID_LIST")] 
        $VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   ParameterSetName='2')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Name")] 
        $VolumeName
    )

    Begin
    {
    $mdmmessage = Connect-SIOmdm
    
    }
    Process
    {
        [bool]$Mapped = $false
        [bool]$MultiMapped = $false
        $object = New-Object -TypeName psobject
        switch ($PsCmdlet.ParameterSetName)
            {
            "1"
                {
                write-verbose $VolumeID
                $Volumequery = scli --query_volume --volume_id $VolumeID --mdm_ip $Global:mdm # 2> $null
                }
            "2"
                {
                $Volumequery = scli --query_volume --volume_name $VolumeName --mdm_ip $Global:mdm  2> $null
                }
            }
        If ($LASTEXITCODE -eq 0)
            {
            if ($Volumequery -match "Mapped SDCs:")
                {
                Write-Verbose "Volume is multimapped"
                [bool]$MultiMapped = $true
            }
            if ($Volumequery -match "SDC ID:")
                {
                Write-Verbose "Volume is mapped"
                [bool]$Mapped = $true
                }

            if ($Volumequery -match " Snapshot of ")
                {
                $Type = "Snapshot"
                }
            elseif ($Volumequery -match " Thin-provisioned")
            {
            $Type = "Thin"
            }
            elseif ($Volumequery -Match " Thick")
            {
            $type = "Thick"
            }
        ### Volume ####
        
        $IDTag = ">> Volume ID: "
        $Convert = Convert-line -Value ($Volumequery | where {$_ -match $IDTag}) -Field1 $Nametag -IDTag $IDTag
        $Object | Add-Member -MemberType NoteProperty -Name VolumeName -Value $Convert.Field1
        $Object | Add-Member -MemberType NoteProperty -Name VolumeID -Value $Convert.id
        $Object | Add-Member -MemberType NoteProperty -Name Type -Value $Type
        $object | Add-Member -MemberType NoteProperty -Name Mapped -Value $Mapped
        $object | Add-Member -MemberType NoteProperty -Name MultiMapped -Value $MultiMapped


        #### Pool   ####
        $IDTag = "   Storage Pool "
        $Convert = Convert-line -Value ($Volumequery | where {$_ -match $IDTag}) -Field1 $Nametag -IDTag $IDTag
        $Object | Add-Member -MemberType NoteProperty -Name Pool -Value $Convert.Field1
        $Object | Add-Member -MemberType NoteProperty -Name PoolID -Value $Convert.id

        #### Protection Domain   ####
        $IDTag = "   Protection Domain "
        $Convert = Convert-line -Value ($Volumequery | where {$_ -match $IDTag}) -Field1 $Nametag -IDTag $IDTag
        $Object | Add-Member -MemberType NoteProperty -Name ProtectionDomain -Value $Convert.Field1
        $Object | Add-Member -MemberType NoteProperty -Name PDid -Value $Convert.id
        #####Mapped SDC
        if ($Mapped)
            {
            $SDSout = @()
            $IDTag = "      SDC ID: "
            $Field2 = "IP: "
            write-verbose "testing SDC´s"
            $SDSlist = $Volumequery | where {$_ -match $IDTag}
            foreach ($SDS in $SDSlist)
                {
                $SDSobject = New-Object -TypeName psobject
                $Convert = Convert-line -Value $SDS -Field1 $Nametag -IDTag $IDTag -Field2 $Field2
                $SDSObject | Add-Member -MemberType NoteProperty -Name SDCID -Value $Convert.id
                $SDSObject | Add-Member -MemberType NoteProperty -Name IPAddress -Value $Convert.Field1
                $SDSObject | Add-Member -MemberType NoteProperty -Name VolumeName -Value $convert.Field2
                $SDSout += $SDSobject
                }
            
            $Object | Add-Member -MemberType NoteProperty -Name SDC -Value $SDSout

            }
        Write-Output $object
        }
        If ($LASTEXITCODE -eq 7)
            {
            Write-Error "Volume $VolumeID $VolumeName not found"
            }
        }
    
    End
    {
    }

}



<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Get-SIOVtree
{
    [CmdletBinding(DefaultParameterSetName='1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    # [OutputType([String])]
    Param
    (
    # Specify the SIO Volume ID  
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   ParameterSetName='1')]
        [validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]
        [Alias("SDC_VOLUME_ID_LIST")] 
        $VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   ParameterSetName='2')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Name")] 
        $VolumeName
    )

    Begin
    {
    $mdmmessage = Connect-SIOmdm
    
    }
    Process
    {
        $object = New-Object -TypeName psobject
        switch ($PsCmdlet.ParameterSetName)
            {
            "1"
                {
                write-verbose $VolumeID
                $SIOVolume = Get-SIOVolume -VolumeID $VolumeID
                }
            "2"
                {
                $SIOVolume = Get-SIOVolume -VolumeName $VolumeName
                }
            }
        If ($SIOVolume)
            {
            $VolumeProperties = $SIOVolume | Get-SIOVolumeProperties
            $VtreeID = $VolumeProperties.VOLUME_VTREE_ID
            $Vtree = Get-SIOVtreeProperties -VtreeID $VtreeID
            $Volumetable = foreach ($Volid in $VTREE.VTREE_VOLUME_ID_LIST) { Get-SIOVolume -VolumeID $Volid }
            $Object | Add-Member -MemberType NoteProperty -Name VTREEID -Value $VTREEID
            $Object | Add-Member -MemberType NoteProperty -Name VTREEname -Value $Vtree.VTREE_NAME
            $Object | Add-Member -MemberType NoteProperty -Name VTREEVolumes -Value $Vtree.VTREE_NUM_OF_VOLUMES
            $Object | Add-Member -MemberType NoteProperty -Name VTREEVolumeIDs -Value $Vtree.VTREE_VOLUME_ID_LIST
            $object | Add-Member -MemberType NoteProperty -Name Volumes -Value $Volumetable
            Write-Output $object
            }
        Else
            {
            Write-Error "Volume $VolumeID $VolumeName not found"
            }
        }
    
    End
    {
    }

}



<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Get-SIODevice
{
    [CmdletBinding(DefaultParameterSetName='2',SupportsShouldProcess=$true,PositionalBinding=$false,HelpUri = 'http://labbuildr.com/',ConfirmImpact='Medium')]
    Param
    (
    # Specify the SIO Device  
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')]
        [validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")][Alias("DEVICE_ID")] 
        [string]$SIODeviceID,
    # Specify the SDS Name  
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
        [ValidateNotNull()][ValidateNotNullOrEmpty()][Alias("Name")] 
        $SDSName
    )

    Begin
    {
    $mdmmessage = Connect-SIOmdm
    
    }
    Process
    {
        $object = New-Object -TypeName psobject
        switch ($PsCmdlet.ParameterSetName)
            {
            "1"
                {
                $SDS = Get-SIOSDS -SDSName $SDSName
                foreach ( $DeviceID in $SDS.DeviceIDs)
                    {
                    Write-Verbose "Parameter Set by SDSNAME"
                    Get-SIODevice -SIODeviceID $DeviceID
                    }

                }
            "2"
                {
                Write-Verbose "Parameter Set by device ID"
                $Private:SDSDevice = Get-SIODeviceProperties -SIODeviceID $SIODeviceID
                }
            }
        If ($Private:SDSDevice)
            {
            Write-Verbose "got Device $DeviceID"
            $Object | Add-Member -MemberType NoteProperty -Name DeviceName -Value $Private:SDSDevice.DEVICE_NAME
            $Object | Add-Member -MemberType NoteProperty -Name DevicePath -Value $Private:SDSDevice.DEVICE_CURRENT_PATH
            $object | Add-Member -MemberType NoteProperty -Name SDSId -Value $Private:SDSDevice.DEVICE_SDS_ID
            $object | Add-Member -MemberType NoteProperty -Name PoolID -Value $Private:SDSDevice.DEVICE_STORAGE_POOL_ID
            if ([int64]$Capacity = convert-capacity $Private:SDSDevice.DEVICE_MAX_CAPACITY)
                {
                $object | Add-Member -MemberType NoteProperty -Name CapacityGB -Value $Capacity
                }
            else
                {
		        $object | Add-Member -MemberType NoteProperty -Name CapacityGB -Value $Private:SDSDevice.DEVICE_MAX_CAPACITY
                }
           # $Object | Add-Member -MemberType NoteProperty -Name Capacity -Value $Private:SDSDevice.DEVICE_MAX_CAPACITY
            $Object | Add-Member -MemberType NoteProperty -Name DeviceError $Private:SDSDevice.DEVICE_ERR_STATE
            $object | Add-Member -MemberType NoteProperty -Name State -Value $Private:SDSDevice.DEVICE_STATE
            Write-Output $object
            }
        }
    
    End
    {
    }

}



<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Get-SIOStoragePool
{
[CmdletBinding(DefaultParameterSetName='1',
SupportsShouldProcess=$true,
PositionalBinding=$false,
HelpUri = 'http://labbuildr.com/',
ConfirmImpact='Medium')]
Param
(
# Specify the SIO POOL ID
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")][Alias("Pool_ID")]$PoolID,
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='3')]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")][Alias("Protection_domain_ID","ProtectionDomainID")]$PDID,
# Specify the SIO POOL Name
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')]

[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='3')]
[ValidateNotNull()][ValidateNotNullOrEmpty()][Alias("Pool_name")]$PoolName,
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')]
[ValidateNotNull()][ValidateNotNullOrEmpty()][Alias("ProtectionDomainName","Protection_Domain_Name")]$PDName
)   
  

    Begin
    {
    $mdmmessage = Connect-SIOmdm
    }
    Process
    {
        
    switch ($PsCmdlet.ParameterSetName)
       {
            "1"
                {
                $Pool = scli --query_storage_pool --storage_pool_id  $PoolID --mdm_ip $Global:mdm
                }
            "2"
                {
                $Pool = scli --query_storage_pool --protection_domain_name $PDName --storage_pool_name $PoolName --mdm_ip $Global:mdm
                }
            "3"
                {
                $Pool = scli --query_storage_pool --protection_domain_id $PDid --storage_pool_name $PoolName --mdm_ip $Global:mdm
                }

        }
        If ($LASTEXITCODE -eq 0)
            {
            $CurrentThinSize = "0"
            $CurrentThinVolumes = "0"
            Write-Verbose "Found Pool $Pool"
            $CurrentPool = $Pool | where {$_ -match "Storage Pool "}
            $currentPool = $CurrentPool.Replace("Storage Pool ","")
            $currentPool = $currentPool.Replace("(Id: ","")
            $currentPool = $currentPool.Replace(")","")
            $currentPool = $currentPool.SPlit(' ')
            $CurrentPoolID = $currentPool[1]
            $Pool = Get-SIOStoragePoolProperties -PoolID $CurrentPoolID
            

            $object = New-Object -TypeName psobject

		    $Object | Add-Member -MemberType NoteProperty -Name PoolName -Value $Pool.STORAGE_POOL_NAME
		    $object | Add-Member -MemberType NoteProperty -Name PoolID -Value $Pool.STORAGE_POOL_ID
            if ([int64]$Capacity = convert-capacity $Pool.STORAGE_POOL_MAX_CAPACITY_IN_KB)
                {
                $object | Add-Member -MemberType NoteProperty -Name CapacityGB -Value ([int64]$Capacity)
                }
            else
                {
		        $object | Add-Member -MemberType NoteProperty -Name CapacityGB -Value $Pool.STORAGE_POOL_MAX_CAPACITY_IN_KB
                }
            if ([int64]$Capacity = convert-capacity $Pool.STORAGE_POOL_UNUSED_CAPACITY_IN_KB)
                {
                $object | Add-Member -MemberType NoteProperty -Name UnusedCapacityGB -Value ([int64]$Capacity)
                }
            else
                {
                $object | Add-Member -MemberType NoteProperty -Name UnusedCapacityGB -Value $Pool.STORAGE_POOL_UNUSED_CAPACITY_IN_KB
                }
		    $object | Add-Member -MemberType NoteProperty -Name Volumes -Value $Pool.STORAGE_POOL_NUM_OF_VOLUMES
		    $object | Add-Member -MemberType NoteProperty -Name ThinVolumes -Value $Pool.STORAGE_POOL_NUM_OF_THIN_BASE_VOLUMES
		    $object | Add-Member -MemberType NoteProperty -Name ThickVolumes -Value $Pool.STORAGE_POOL_NUM_OF_THICK_BASE_VOLUMES
		    $object | Add-Member -MemberType NoteProperty -Name UnmappedVolumes -Value $Pool.STORAGE_POOL_NUM_OF_UNMAPPED_VOLUMES
            Write-Output $object
            }

        Else
            {
            Write-Error "SCLI exit : $sclierror"
            }              
    }
    End
    {
     }

}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Get-SIOSDS
{
    [CmdletBinding(DefaultParameterSetName='1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    Param
    (


        # Specify the SIO SDS ID  
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   ParameterSetName='1')]
        [validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]
        [Alias("ID")] 
        $SDSID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true, 
                   ParameterSetName='2')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias("Name")] 
        $SDSName
    )


    Begin
    {
    $mdmmessage = Connect-SIOmdm
    }
    Process
    {
        
    switch ($PsCmdlet.ParameterSetName)
       {
            "1"
                {
                $SDSquery = scli --query_sds --sds_id $SDSID --mdm_ip $Global:mdm
                    
                }
            "2"
                {
                $SDSquery = scli --query_sds --sds_name $SDSName --mdm_ip $Global:mdm 
                }
        }
        If ($LASTEXITCODE -eq 0)
            { 
            $Currentsds = $SDSquery | where {$_ -match "SDS $SDSID"}
                    $currentSDS = $Currentsds.Replace("SDS ","")
                    $currentSDS = $currentSDS.Replace(" Name:","")
                    $currentSDS = $currentSDS.SPlit(' ')
                    $CurrentSDSID = $currentSDS[0]
                    $CurrentSDSname = $currentSDS[1]
            $currentpd = $SDSquery | where { $_ -match "Protection Domain:" }
                    $currentPD = $currentpd.Replace("Protection Domain: ","")
                    $currentPD = $currentPD.Replace(", Name:","")
                    $currentPD = $currentPD.SPlit(' ')
                    $CurrentPDname = $currentPD[1]
                    $CurrentPDID = $currentPD[0]
            $CurrentDevs =  $SDSquery | where {$_ -match "Original-path:"}
                    $DeviceID = @()
                    foreach ($Device in $CurrentDevs)
                        {
                        $DeviceID += ($Device.split(" "))[-1]
                        }
                    Write-Verbose "Found SDS $SDS"
                    $object = New-Object -TypeName psobject
		            $Object | Add-Member -MemberType NoteProperty -Name SDSName -Value $CurrentSDSname
		            $object | Add-Member -MemberType NoteProperty -Name SDSID -Value $CurrentSDSID
		            $object | Add-Member -MemberType NoteProperty -Name PDName -Value $CurrentPDname
		            $Object | Add-Member -MemberType NoteProperty -Name PDID -Value $CurrentPDID
		            $Object | Add-Member -MemberType NoteProperty -Name DeviceIDs -Value $DeviceID

                    Write-Output $object
                }

        Else
            {
            Write-Error "SCLI exit : $sclierror"
            }              
    }
    End
    {
     }

}


<#
.Synopsis
Short description
.DESCRIPTION
Long description
.EXAMPLE
Example of how to use this cmdlet
.EXAMPLE
Another example of how to use this cmdlet
.INPUTS
Inputs to this cmdlet (if any)
.OUTPUTS
Output from this cmdlet (if any)
.NOTES
General notes
.COMPONENT
The component this cmdlet belongs to
.ROLE
The role this cmdlet belongs to
.FUNCTIONALITY
The functionality that best describes this cmdlet
#>
function Get-SIOSDC
{
[CmdletBinding(DefaultParameterSetName='1',
SupportsShouldProcess=$true,
PositionalBinding=$false,
HelpUri = 'http://labbuildr.com/',
ConfirmImpact='Medium')]
Param
(
# Specify the SIO SDC ID
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]
[Alias("ID")]$SDCID,
# Specify the SIO SDC Name
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')]
[ValidateNotNull()][ValidateNotNullOrEmpty()][Alias("Name")]$SDCName
<# Specify the SIO SDC GUID
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='3')]
[ValidateNotNull()][ValidateNotNullOrEmpty()][Alias("Guid")][string]$SDCguid
#>
)
Begin
{
$mdmmessage = Connect-SIOmdm
}
Process
{
switch ($PsCmdlet.ParameterSetName)
    {
        "1"
        {
        $sdcquery = scli --query_sdc --sdc_id $SDCID --mdm_ip $Global:mdm
        }
        "2"
        {
        $sdcquery = scli --query_sdc --sdc_name $SDCName --mdm_ip $Global:mdm
        }
        "3"
        {
        Write-Verbose "query sdc by GUID $SDCguid"
        $sdcquery = scli --query_sdc --sdc_guid $SDCguid --mdm_ip $Global:mdm
        }
    }
If ($LASTEXITCODE -ne 0)
{
write-error "Could not find SDC"
break
}
if ($sdcquery -match "SDC ID:")
{
$currentsdc = $SDCquery.Replace("SDC ID: ","")
$currentsdc = $currentsdc.Replace(" Name:","")
$currentsdc = $currentsdc.Replace(" IP:","")
$currentsdc = $currentsdc.Replace(" State:","")
$currentsdc = $currentsdc.Replace(" GUID:","")
$currentsdc = $currentsdc.SPlit(' ')
$Currentsdcname = $currentsdc[1]
$CurrentsdcID = $currentsdc[0]
$CurrentsdcIP = $currentsdc[2]
$CurrentsdcState = $currentsdc[3]
$CurrentsdcGuid = $currentsdc[4]
Write-Verbose "Found SDC $SDC"

$object = New-Object -TypeName psobject
$Object | Add-Member -MemberType NoteProperty -Name SDCName -Value $Currentsdcname
$object | Add-Member -MemberType NoteProperty -Name SDCID -Value $CurrentsdcID
$object | Add-Member -MemberType NoteProperty -Name IP -Value $CurrentsdcIP
$Object | Add-Member -MemberType NoteProperty -Name State -Value $CurrentsdcState
$object | Add-Member -MemberType NoteProperty -Name GUID -Value $CurrentsdcGuid
Write-Output $object
}
}
End
{
}
}

<#
.Synopsis
Short description
.DESCRIPTION
Long description
.EXAMPLE
Example of how to use this cmdlet
.EXAMPLE
Another example of how to use this cmdlet
.INPUTS
Inputs to this cmdlet (if any)
.OUTPUTS
Output from this cmdlet (if any)
.NOTES
General notes
.COMPONENT
The component this cmdlet belongs to
.ROLE
The role this cmdlet belongs to
.FUNCTIONALITY
The functionality that best describes this cmdlet
#>
function Get-SIOSDCvolume
{
[CmdletBinding(DefaultParameterSetName='1',
SupportsShouldProcess=$true,
PositionalBinding=$false,
HelpUri = 'http://labbuildr.com/',
ConfirmImpact='Medium')]
Param
(
# Specify the SIO SDC ID
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]
[Alias("ID")]$SDCID,
# Specify the SIO SDC Name
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')]
[ValidateNotNull()][ValidateNotNullOrEmpty()][Alias("Name")]$SDCName
<# Specify the SIO SDC GUID
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='3')]
[ValidateNotNull()][ValidateNotNullOrEmpty()][Alias("Guid")][string]$SDCguid
#>
)
Begin
{
# $mdmmessage = Connect-SIOmdm
}
Process
{
switch ($PsCmdlet.ParameterSetName)
    {
        "1"
        {
        Write-Verbose "Query by ID"
        $private:sdcproperties = Get-SIOSDCProperties -SDCID $SDCID
        }
        "2"
        {
        $sdcquery = Get-SIOSDC -SDCName $SDCName
        if ($sdcquery)
            {
            $private:sdcproperties = Get-SIOSDCProperties -SDCID $sdcquery.SDCID
            }
        }
        "3"
        {
        Write-Verbose "query sdc device by deviceid"
        #$sdcquery = scli --query_sdc --sdc_guid $SDCguid --mdm_ip $Global:mdm
        }
    }

foreach ($private:volumeid in $private:sdcproperties.SDC_VOLUME_ID_LIST)

    {
    write-verbose $volumeid
    If ( $volumeid -match "[0-9A-F]{16}")
    {
    $private:Volumeprop = Get-SIOVolumeProperties -VolumeID $private:volumeid -ErrorAction SilentlyContinue
    
    $object = New-Object -TypeName psobject
    $object | Add-Member -MemberType NoteProperty -Name VolumeID -Value $private:Volumeprop.VOLUME_ID
    $object | Add-Member -MemberType NoteProperty -Name VolumeName -Value $private:Volumeprop.VOLUME_NAME
    $object | Add-Member -MemberType NoteProperty -Name SDCNAME -Value $private:sdcproperties.SDC_NAME
    if ([System.Double]$Capacity = convert-capacity $private:Volumeprop.VOLUME_SIZE)
        {
        $object | Add-Member -MemberType NoteProperty -Name CapacityGB -Value ([System.Double]$Capacity)
        }
    else
        {
        $object | Add-Member -MemberType NoteProperty -Name Capacity -Value $private:Volumeprop.VOLUME_SIZE
        }
    $object | Add-Member -MemberType NoteProperty -Name VolumeType -Value $private:Volumeprop.VOLUME_TYPE

    Write-Output $object
    }

    }
    <#
$currentsdc = $SDCquery.Replace("SDC ID: ","")
$currentsdc = $currentsdc.Replace(" Name:","")
$currentsdc = $currentsdc.Replace(" IP:","")
$currentsdc = $currentsdc.Replace(" State:","")
$currentsdc = $currentsdc.Replace(" GUID:","")
$currentsdc = $currentsdc.SPlit(' ')
$Currentsdcname = $currentsdc[1]
$CurrentsdcID = $currentsdc[0]
$CurrentsdcIP = $currentsdc[2]
$CurrentsdcState = $currentsdc[3]
$CurrentsdcGuid = $currentsdc[4]
Write-Verbose "Found SDC $SDC"

$object = New-Object -TypeName psobject
$Object | Add-Member -MemberType NoteProperty -Name SDCName -Value $Currentsdcname
$object | Add-Member -MemberType NoteProperty -Name SDCID -Value $CurrentsdcID
$object | Add-Member -MemberType NoteProperty -Name IP -Value $CurrentsdcIP
$Object | Add-Member -MemberType NoteProperty -Name State -Value $CurrentsdcState
$object | Add-Member -MemberType NoteProperty -Name GUID -Value $CurrentsdcGuid
Write-Output $object
#>
}
End
{
}
}


function Rename-SIOSDC
{
[CmdletBinding(DefaultParameterSetName='1',
SupportsShouldProcess=$true,
PositionalBinding=$false,
HelpUri = 'http://labbuildr.com/',
ConfirmImpact='Medium')]
Param
(
# Specify the SIO SDC ID
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]
[Alias("ID")]
$SDCID,
# Specify the SIO SDC Name
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')]
[ValidateNotNull()][ValidateNotNullOrEmpty()][Alias("Name")]$SDCName,
<# Specify the SIO SDC GUID
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='3')]
[ValidateNotNull()][ValidateNotNullOrEmpty()][Alias("Guid")]$SDCguid,
#>
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
[ValidateNotNull()][ValidateNotNullOrEmpty()][Alias("NewName")]$NewSDCName

)
Begin
{
$mdmmessage = Connect-SIOmdm
}
Process
{
    switch ($PsCmdlet.ParameterSetName)
    {
    "1"
        {
        Write-Verbose "query sdc by id $SDCID"
        $sdcquery = Get-SIOSDC -SDCID $SDCID
        }
    "2"
        {
        Write-Verbose "query sdc by name $SDCName"
        $sdcquery = Get-SIOSDC -SDCName $SDCName
        }
    "3"
        {
        Write-Verbose "query sdc by GUID $SDCguid"
        $sdcquery = Get-SIOSDC -SDCGuid $SDCguid
        }
    }
    If ($LASTEXITCODE -eq 0)
        {
        Write-Verbose  $($sdcquery.sdcid)
        $rename = scli --rename_sdc --sdc_id $($sdcquery.sdcid) --new_name $NewSDCName --mdm_ip $Global:mdm
        If ($LASTEXITCODE -eq 0)
            {
            get-siosdc -SDCName $NewSDCName
            }
        else
            {
            Write-Warning $LASTEXITCODE
            }
        }
    else
        {
        write-error "Could not find SDC"
        }
    }

End
{
}
}




function Rename-SIOStoragePool
{
[CmdletBinding(DefaultParameterSetName='1',
SupportsShouldProcess=$true,
PositionalBinding=$false,
HelpUri = 'http://labbuildr.com/',
ConfirmImpact='Medium')]
Param
(
# Specify the SIO POOL ID
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")][Alias("Pool_ID")]$PoolID,
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='3')]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")][Alias("Protection_domain_ID")]$PDID,
# Specify the SIO POOL Name
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')]
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='3')]
[ValidateNotNull()][ValidateNotNullOrEmpty()][Alias("Pool_name")]$PoolName,
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')]
[ValidateNotNull()][ValidateNotNullOrEmpty()][Alias("Protection_domain_name")]$PDName,
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
[ValidateNotNull()][ValidateNotNullOrEmpty()][Alias("NewName")]$NewPoolName

)
Begin
{
$mdmmessage = Connect-SIOmdm
}
Process
{
    switch ($PsCmdlet.ParameterSetName)
    {
    "1"
        {
        }
    "2"
        {
        Write-Verbose "query by names $PoolName $PDName"
        $Pool = Show-SIOPools | where {($_.Poolname -match $PoolName) -and ($_.ProtectionDomainName -eq $PDName)}
        }
    "3"
        {
        }

    }
   If ($Pool)
        {
        Write-Verbose  $($Pool.PoolName)
        $rename = scli --rename_storage_pool --storage_pool_id $($Pool.PoolID) --protection_domain_id $($Pool.ProtectionDomainID) --new_name $NewPoolName --mdm_ip $Global:mdm
        If ($LASTEXITCODE -eq 0)
            {
            Show-SIOPools | where {($_.Poolname -match $NewPoolName) -and ($_.ProtectionDomainName -eq $PDName)}
            }
        else
            {
            Write-Warning $LASTEXITCODE
            }
        }
    else
        {
        write-error "Could not find Pool"
        }
    }

End
{
}
}




<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
        ID:      85e22974f30ae694
        Name:     ScaleIO@labbuildr

License info:
        Installation ID: d078c73806bc9481
        SWID:
        Maximum capacity: Unlimited
        Usage time left: 20 days (Initial License)
        Enterprise features: Enabled
        The system was activated 10 days ago
#>
function Show-SIOSystemInfo
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    Param
    (
    )

    Begin
    {
    $mdmmessage = Connect-SIOmdm
    }
    Process
    {
    $Systeminfo = scli --query_all --mdm_ip $mdm 2> $sclierror
    $Product = $Systeminfo | Where {$_ -match "Product:  "}
    $Product = $Product.replace("`t","")
    $Product = $Product.Replace("Product:  ","")
    $Product = $Product.Replace("Version:",",")
    $Product = $Product.SPlit(',')
    $SystemID = $Systeminfo | Where {$_ -match "ID:  "}
    $SystemID = $SystemID.replace("`t","")
    $SystemID = $SystemID.Replace("ID:  ","")
    $SystemID = $SystemID.Replace(" ","")
    $SystemName = $Systeminfo | Where {$_ -match "Name:  "}
    $SystemName = $SystemName.replace("`t","")
    $SystemName = $SystemName.Replace("Name:  ","")
    $SystemName = $SystemName.Replace(" ","")


    $object = New-Object -TypeName psobject
	$Object | Add-Member -MemberType NoteProperty -Name Product -Value $Product[0]
	$object | Add-Member -MemberType NoteProperty -Name Version -Value $Product[1].TrimStart(" ")
	$Object | Add-Member -MemberType NoteProperty -Name SystemID -Value $SystemID
	$Object | Add-Member -MemberType NoteProperty -Name SystemName -Value $SystemName

    Write-Output $object
    }
    End
    {}
}

#SDC ID: 0430f6b000000000 Name: hvnode1 IP: 192.168.2.151 State: Connected GUID: 7202918A-5010-154E-A51E-032A73F2CDC2#
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Show-SIOSDCs
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    Param
    (
    )

    Begin
    {
    $mdmmessage = Connect-SIOmdm
    }
    Process
    {

    $SDCS = scli --query_all_sdc --mdm_ip $Global:mdm 2> $sclierror
    if ($LASTEXITCODE -eq 0)
        {
        foreach ($SDC in $SDCS )
            {
            
            if ($SDC -match "SDC ID:")
                {
                    $currentSDC = $SDC.Replace("SDC ID: ","")
                    $currentSDC = $currentSDC.Replace(" Name:","")
                    $currentSDC = $currentSDC.Replace(" IP:","")
                    $currentSDC = $currentSDC.Replace(" State:","")
                    $currentSDC = $currentSDC.Replace(" GUID:","")
                    $currentSDC = $currentSDC.SPlit(' ')
                    $CurrentSDCname = $currentSDC[1]
                    $CurrentSDCID = $currentSDC[0]
                    $CurrentSDCIP = $currentSDC[2]
                    $CurrentSDCState = $currentSDC[3]
                    $CurrentSDCGuid = $currentSDC[4]
                    Write-Verbose "Found SDC $SDC"
                    $object = New-Object -TypeName psobject
		            $Object | Add-Member -MemberType NoteProperty -Name SDCName -Value $CurrentSDCname
		            $object | Add-Member -MemberType NoteProperty -Name SDCID -Value $CurrentSDCID
		            $object | Add-Member -MemberType NoteProperty -Name IP -Value $CurrentSDCIP
		            $Object | Add-Member -MemberType NoteProperty -Name State -Value $CurrentSDCState
		            $object | Add-Member -MemberType NoteProperty -Name GUID -Value $CurrentSDCGuid
                    Write-Output $object
                }


            }
        

        }
    Else
        {
        Write-Error "SCLI exit : $sclierror"
        }   
    }
    End
    {}

}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Show-SIOSDSs
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    Param
    (
    )

    Begin
    {
    $mdmmessage = Connect-SIOmdm
    }
    Process
    {

    $SDSS = scli --query_all_sds --mdm_ip $Global:mdm 2> $sclierror
    if ($LASTEXITCODE -eq 0)
        {
        foreach ($SDS in $SDSS )
            {
            
            if ($SDS -match "SDS ID:")
                {
                    $currentSDS = $SDS.Replace(", ","-")
                    $currentSDS = $currentSDS.Replace("SDS ID: ","")
                    $currentSDS = $currentSDS.Replace(" Name:","")
                    $currentSDS = $currentSDS.Replace(" State:","")
                    $currentSDS = $currentSDS.Replace(" IP:","")
                    $currentSDS = $currentSDS.Replace(" Port:","")
                    $currentSDS = $currentSDS.SPlit(' ')
                    $CurrentSDSname = $currentSDS[1]
                    $CurrentSDSID = $currentSDS[0]
                    $CurrentSDSState = $currentSDS[2]
                    $CurrentSDSIP = $currentSDS[3]
                    $CurrentSDSPort = $currentSDS[4]
                    Write-Verbose "Found SDS $SDS"
                    $object = New-Object -TypeName psobject
		            $Object | Add-Member -MemberType NoteProperty -Name SDSName -Value $CurrentSDSname
		            $object | Add-Member -MemberType NoteProperty -Name SDSID -Value $CurrentSDSID
		            $object | Add-Member -MemberType NoteProperty -Name IP -Value $CurrentSDSIP
		            $Object | Add-Member -MemberType NoteProperty -Name State -Value $CurrentSDSState
		            $object | Add-Member -MemberType NoteProperty -Name Port -Value $CurrentSDSPort
                    Write-Output $object
                }


            }
        

        }
    Else
        {
        Write-Error "SCLI exit : $sclierror"
        }   
    }
    End
    {}

}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function convert-line
{
[CmdletBinding(DefaultParameterSetName='1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
Param(
[string]$Value,
[String]$Field1,
[String]$Field2,
[String]$IDTag
)

$Short = $Value.replace("$IDTag","")
$Short = $Short.replace("$Field1","")
If ($Field2)
    {
    $Short = $Short.replace("$Field2","")
    Write-verbose "Replacing $Field2"
    }
$Short = $Short.split(" ")
Write-Verbose " We Stripped name $($Short[1]) and ID $($short[0])"
$object = New-Object -TypeName psobject
$Object | Add-Member -MemberType NoteProperty -Name ID $Short[0]
$Object | Add-Member -MemberType NoteProperty -Name Field1 -Value $Short[1]
If ($short[2])
    {
    $Object | Add-Member -MemberType NoteProperty -Name Field2 -Value $Short[2]
    }
Write-Output $object
}

<#
.Synopsis
   unmaps a volume from an SDC
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Disconnect-SIOVolume
{
    [CmdletBinding(DefaultParameterSetName='1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    # [OutputType([String])]
    Param
    (
    # Specify by ID  
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='3')]
        [validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]
        [Alias("ID")]$VolumeID,
        [Parameter(Mandatory=$True,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
        [validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]
        $SDCId,
    # Specify by  Name  
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')]
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='3')]
        [Alias("Name")]$VolumeName,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')]$SDCName,
    # Specify All SDC´s 
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='3')][switch]$All



    )#end param
begin {}
process 
{
switch ($PsCmdlet.ParameterSetName)
    {
            "1"
                {
                Write-Verbose $VolumeID
                $Volumequery = Get-SIOVolume -VolumeID $VolumeID
                Write-Verbose $SDCID
                $SDCquery = Get-SIOSDC -SDCID $SDCId
                    
                }
            "2"
                {
                Write-Verbose $VolumeName
                $Volumequery = Get-SIOVolume -VolumeName $VolumeName
                Write-Verbose $SDCname
                $SDCquery = Get-SIOSDC -SDCName $SDCName

                }
            "3"
                {
                Write-Verbose $VolumeName
                $Volumequery = Get-SIOVolume -VolumeName $VolumeName
                }
     }
if (($Volumequery -and $SDCquery) -or ($Volumequery -and $All.IsPresent))
    {
    $Volumequery
    $commit = 0
    if ($ConfirmPreference -match "low")
        { $commit = 1 }
    else
        {
        If ($all.IsPresent)
            {
            $commit = Get-yesno -title "Commit Volume Unmap" -message "This will unmap the above Volume from all Hosts"
            }
        Else
            {
            $commit = Get-yesno -title "Commit Volume Unmap" -message "This will unmap the above Volume from $($SDCquery.SDCid)"
            }
        }
    Switch ($commit)
        {
            1
            {
            If ($all.IsPresent)
                {
                Write-Verbose "Unampping Volume from all SDC´s"
                scli --unmap_volume_from_sdc --volume_id $($Volumequery.Volumeid) --all_sdcs --i_am_sure --mdm_ip $Global:mdm 
                }
            Else
                {
                Write-Verbose "Unampping Volume from SDC $($SDC.SDCid)"
                scli --unmap_volume_from_sdc --volume_id $($Volumequery.Volumeid) --sdc_id $SDCquery.SDCid --i_am_sure --mdm_ip $Global:mdm 
                }
            }  
        }
    }
Else
    {
        write-error "Volume $VolumeID $VolumeName or SDC $SDCid $SDCName not found"
        }
    

}
end {}
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Connect-SIOVolume
{
    [CmdletBinding(DefaultParameterSetName='1', 
                  SupportsShouldProcess=$true, 
                  # PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    # [OutputType([String])]
    Param
    (
    # Parameter Set by ID 
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
        [validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]
        [Alias("ID")]$VolumeID,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
        [validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]$SDCID,
    # Parameter Set by Name
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')]
        [Alias("Name")]$VolumeName,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')]
        [string]$SDCName
    )#end param
begin
{}
process 
{
switch ($PsCmdlet.ParameterSetName)
    {
            "1"
                {
                $Volumequery = Get-SIOVolume -VolumeID $VolumeID
                $SDC = Get-SIOSDC -SDCid $SDCID  
                Write-Verbose "$SDCID" 
                }
            "2"
                {
                $Volumequery = Get-SIOVolume -VolumeName $VolumeName
                $SDC = Get-SIOSDC -SDCName $SDCName
                Write-Verbose $SDCName
                }
     }
if (!($Volumequery))
    {
    write-error "Volume $VolumeID $VolumeName not found"
    Break
    }
if (!($SDC))
    {
    write-error "SDC $SDCID $SDCName not found"
    Break
    }

    scli --map_volume_to_sdc --volume_id $($Volumequery.VolumeId) --sdc_id $($SDC.SDCid) --allow_multi_map --mdm_ip $Global:mdm 
    if ($LASTEXITCODE -eq 0)
        {
        Get-SIOVolume -VolumeID ($Volumequery.VolumeId)
        }
    Else
        {
        Write-Error "SCLI exit : $sclierror"
        }   
} #end_p
end
{}
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Remove-SIOVolume
{
    [CmdletBinding(DefaultParameterSetName='1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    # [OutputType([String])]
    Param
    (
    # Specify the SIO Volume ID  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
        [validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]
        [Alias("ID")]$VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')][Alias("Name")]$VolumeName
    )#end param
begin {}
process 
{
switch ($PsCmdlet.ParameterSetName)
    {
            "1"
                {
                $Volumequery = Get-SIOVolume -VolumeID $VolumeID
                    
                }
            "2"
                {
                $Volumequery = Get-SIOVolume -VolumeName $VolumeName
                }
     }
if (!($Volumequery))
    {
    write-error "Volume $VolumeID $VolumeName not found"
    Break
    }
Else
    {
    $Volumequery
    $commit = 0
    if ($ConfirmPreference -match "low")
        { $commit = 1 }
    else
        {
        $commit = Get-yesno -title "Commit Volume Deletion" -message "This will delete the above Volume"
        }
    Switch ($commit)
        {
            1
            {
            scli --remove_volume --volume_id $($Volumequery.VolumeID) --i_am_sure --mdm_ip $Global:mdm 
            
            }
        }
    } 


}
end {}
}



<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Remove-SIOVolumeTree
{
    [CmdletBinding(DefaultParameterSetName='1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    # [OutputType([String])]
    Param
    (
    # Specify the SIO Volume ID  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
        [validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]
        [Alias("ID")]$VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')][Alias("Name")]$VolumeName


    )#end param
begin {}
process 
{
switch ($PsCmdlet.ParameterSetName)
    {
            "1"
                {
                $Volumequery = Get-SIOVolume -VolumeID $VolumeID
                    
                }
            "2"
                {
                $Volumequery = Get-SIOVolume -VolumeName $VolumeName
                }
     }
if ($LASTEXITCODE -ne 0)
    {
    write-error "Volume $VolumeID $VolumeName not found"
    Break
    }
Else
    {
    $Volumequery
    $commit = 0
    if ($ConfirmPreference -match "low")
        { $commit = 1 }
    else
        {
        $commit = Get-yesno -title "Commit Snapshot Deletion" -message "This will delete the Entire Tree including the above Volume"
        }
    Switch ($commit)
        {
            1
            {
            scli --remove_volume --volume_id $($Volumequery.VolumeID) --i_am_sure --remove_entire_snapshot_tree --mdm_ip $Global:mdm 2> $sclierror
            IF ($LASTEXITCODE -ne 0)
                {
                Write-Error "SCLI exit : $sclierror"
                }   
            }
        }
    } 
}
end {}
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Remove-SIOSnapshotTree
{
    [CmdletBinding(DefaultParameterSetName='1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    # [OutputType([String])]
    Param
    (
    # Specify the SIO Volume ID  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
        [validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]
        [Alias("ID")]$VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')][Alias("Name")]$VolumeName
    )#end param
begin {}
process 
{
switch ($PsCmdlet.ParameterSetName)
    {
            "1"
                {
                $Volumequery = Get-SIOVolume -VolumeID $VolumeID
                    
                }
            "2"
                {
                $Volumequery = Get-SIOVolume -VolumeName $VolumeName
                }
     }
if (!($Volumequery))
    {
    write-error "Volume $VolumeID $VolumeName not found"
    Break
    }
Else
    {
    
    $Volumequery
    $commit = 0
    if ($ConfirmPreference -match "low")
        { $commit = 1 }
    else
        {
        $commit = Get-yesno -title "Commit Snapshot Deletion" -message "This will delete the Entire Snapshot Tree of the above Volume"
        }
    Switch ($commit)
        {
            1
            {
            scli --remove_volume --volume_id $($Volumequery.VolumeID) --i_am_sure --remove_descendant_snapshots_only --mdm_ip $Global:mdm
          
            }
        }
    } 
}
end {}
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function Remove-SIOSnapshotTreewithParents
{
    [CmdletBinding(DefaultParameterSetName='1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    # [OutputType([String])]
    Param
    (
    # Specify the SIO Volume ID  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]
        [validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]
        $VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')][Alias("Name")]$VolumeName
    )#end param
begin {}
process 
{
switch ($PsCmdlet.ParameterSetName)
    {
            "1"
                {
                $Volumequery = Get-SIOVolume -VolumeID $VolumeID
                    
                }
            "2"
                {
                $Volumequery = Get-SIOVolume -VolumeName $VolumeName
                }
     }
if (!($Volumequery))
    {
    write-error "Volume $VolumeID $VolumeName not found"
    Break
    }
Else
    {
    
    $Volumequery
    $commit = 0
    if ($ConfirmPreference -match "low")
        { $commit = 1 }
    else
        {
        $commit = Get-yesno -title "Commit Snapshot Deletion" -message "This will delete the Entire Snapshot Tree of the above Volume Including Parents"
        }
    Switch ($commit)
        {
            1
            {
            scli --remove_volume --volume_id $($Volumequery.VolumeID) --i_am_sure --remove_with_descendant_snapshots --mdm_ip $Global:mdm 2> $sclierror
            if ($LASTEXITCODE -ne 0)
                {
                Write-Error "SCLI exit : $sclierror"
                }   
            
            }
        }
    } 
}
end {}
}

<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function New-SIOSnapshot
{
    [CmdletBinding(DefaultParameterSetName='1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    # [OutputType([String])]
    Param
    (
    # Specify the SIO Volume ID  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')]
        [validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]
        [Alias("ID")]$VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')][Alias("Name")]$VolumeName,
    # Specify the SNAP Name, if none specified one will be generated from source and time  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)][Alias("SN")]$SnapName

    )#end param
begin 
{
$Snapsource = @()
$SnaptarGet = @()
if (!$Snapname) {$SnapName = Get-date -Format hhmmss }$Congroup = $false

}
process 
{
switch ($PsCmdlet.ParameterSetName)
    {
            "1"
                {
                $Volumequery = Get-SIOVolume -VolumeID $VolumeID
                    
                }
            "2"
                {
                $Volumequery = Get-SIOVolume -VolumeName $VolumeName
                }
     }
if (!($Volumequery))
    {
    write-error "Volume $VolumeID $VolumeName not found, $sclierror"
    Break
    }
Else
    {
    $Snapsource += $Volumequery.VolumeId
    $SnaptarGet += "$($Volumequery.VolumeName.Substring(0,5))_$Snapname"
    } 
}
end {
    write-verbose ($Snapsource -Join ',')
    $Snapshots = scli --snapshot_volume --volume_id ($Snapsource -Join ',') --snapshot_name ($SnaptarGet -Join ',') --mdm_ip $Global:mdm 2> $sclierror
    $Congroup = "Consistency group ID: "
    $Ident = "    Source volume with ID "
    $Arrow = "=> "
    $Snappairs = $Snapshots | where {$_ -match $Ident}
    If ($Snapshots -match $Congroup)
        {
        $HasConGroup = $true
        $ConGroupid = $Snapshots | where {$_ -match $Congroup}
        $CongroupID= $ConGroupid.Replace($Congroup,"")
        }
    foreach ($Snappair in $Snappairs)
        {
        $Snappair = $Snappair.replace($Ident,"")
        $Snappair = $Snappair.replace($Arrow,"")
        $Snappair = $Snappair.Split(" ")
        Write-Verbose ($Snappair -join "-")
        $object = New-Object -TypeName psobject
        $Object | Add-Member -MemberType NoteProperty -Name SourceID $Snappair[0]
        $Object | Add-Member -MemberType NoteProperty -Name SnapID -Value $Snappair[1]
        $Object | Add-Member -MemberType NoteProperty -Name Snapname -Value $Snappair[2]
        $Object | Add-Member -MemberType NoteProperty -Name Congroup -Value $HasConGroup
        $Object | Add-Member -MemberType NoteProperty -Name CongroupID -Value $ConGroupid
        Write-Output $object   
        }
        

}
}


<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   General notes
.COMPONENT
   The component this cmdlet belongs to
.ROLE
   The role this cmdlet belongs to
.FUNCTIONALITY
   The functionality that best describes this cmdlet
#>
function New-SIOVolume
{
    [CmdletBinding(DefaultParameterSetName='1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  HelpUri = 'http://labbuildr.com/',
                  ConfirmImpact='Medium')]
    # [OutputType([String])]
    Param
    (
    # Specify the SIO Protection Domain Name  
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ProtectionDomainName")]$PDName,
    # Specify the SIO Pool Name  
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("PoolName")]$SPName,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')][Alias("SPID")]$PoolID,
    # Specify the New Volume Name  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)][Alias("VN")]$VolumeName,
    # Specify if thin, default thick  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false)][switch]$Thin,
    # Specify the New Volume Size in GB 
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$false)][ValidateRange(1,64000)]$SizeInGB



    )#end param
begin 
{
Connect-SIOmdm | Out-Null
$Extraparam = ""

if ($Thin.IsPresent)
    {$Thinparam = "--thin_provisioned"
    $Extraparam = "$Extraparam $Thinparam"}

Write-Verbose $Extraparam
$Extraparam = $Extraparam.TrimStart(" ")
Write-Verbose $Extraparam
}
process 
{
switch ($PsCmdlet.ParameterSetName)
    {
            "1"
                {
                write-verbose "scli --add_volume --protection_domain_name $PDName --storage_pool_name $SPName --size_gb $SizeInGB $Extraparam --mdm_ip $Global:mdm"
                If ($VolumeName)
                    {
                    $Newvol = scli --add_volume --protection_domain_name $PDName --storage_pool_name $SPName --size_gb $SizeInGB --volume_name $VolumeName $Extraparam --mdm_ip $Global:mdm 2> $sclierror
                    }
                else
                    {
                    $Newvol = scli --add_volume --protection_domain_name $PDName --storage_pool_name $SPName --size_gb $SizeInGB $Extraparam --mdm_ip $Global:mdm  2> $sclierror
                    }

                    
                }
            "2"
                {
                write-verbose "scli --add_volume --storage_pool_id $PoolID --size_gb $SizeInGB $Extraparam --mdm_ip $Global:mdm"
                If ($VolumeName)
                    {
                    $Newvol = scli --add_volume --storage_pool_id $PoolID  --size_gb $SizeInGB --volume_name $VolumeName $Extraparam --mdm_ip $Global:mdm 2> $sclierror
                    }
                else
                    {
                    $Newvol = scli --add_volume --storage_pool_id $PoolID  --size_gb $SizeInGB $Extraparam --mdm_ip $Global:mdm  2> $sclierror
                    }

                
                }
     }

}
end {
        If ($LASTEXITCODE  -eq 0)
            {

            $VolData = ($newvol | where {$_ -match "Successfully"}).Replace("Successfully created volume of size ","")
            $Voldata = $Voldata.Split(" ")
            Get-SIOVolume -VolumeID $VolData[-1]
            }
        Else
            {
            Write-Error "SCLI exit : $sclierror"
            }   
        }
  
}



function Get-mdmobjects
{
[CmdletBinding()]
param(

[string]$props,
$objectid,
$objecttype
)
$properties = $props.split(",")
$Query = scli --query_properties --object_type $objecttype --object_id $objectid --properties $props --mdm_ip $mdm
# $Query
if ($LASTEXITCODE -ne 1)
    {
    # $Query.removerange(0,1)
    $object = New-Object -TypeName psobject
    foreach ($Property in $properties)
        {
            Write-Verbose "now evaluation $Property"
            $Query | foreach {
                $Value = $_
                $line = (($_).Split(" "))[0]
                $Line = $line.replace(" ","")
                if ($line)
                    {
                    if ($line.substring(1) -eq $Property) 
                        {
                        write-verbose $line.substring(1)
                        # $value
                        $Value = $Value.replace("$Property","")
                        $Value = $Value.replace(" ","")
                        $Value = $Value.substring(1)
                        write-verbose $Property
                        Write-Verbose $Value
                        If ($Value -match ",")
                            {
                            $Object | Add-Member -MemberType NoteProperty -Name $objecttype"_"$Property -Value $Value.Split(",")
                            }
                        else
                            {
                            $Object | Add-Member -MemberType NoteProperty -Name $objecttype"_"$Property -Value $Value
                            }
                        }
                    }
                }
    
            }
    Write-Output $object
}
}

function Get-SIOVolumeProperties 
{
[CmdletBinding()]
param (
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("SDCVOLUME_ID_LIST")]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]$VolumeID
)
begin 
{
[string]$Props = "USER_DATA_READ_BWC
USER_DATA_WRITE_BWC
CHILD_VOLUME_ID_LIST
NUM_OF_CHILD_VOLUMES
DESCENDANT_VOLUME_ID_LIST
NUM_OF_DESCENDANT_VOLUMES
NUM_OF_MAPPED_SDCS
NUM_OF_MAPPED_SCSI_INITIATORS
ID
NAME
SIZE
OBFUSCATED
CREATION_TIME
TYPE
CONSISTENCY_GROUP_ID
STORAGE_POOL_ID
VTREE_ID
ANCESTOR_ID
SOURCE_DELETED
MAPPING_TO_ALL_SDCS_ENABLED
USE_RMCACHE"
$Props = $Props.Replace("`n",",")
$Props = $Props.Replace("`r","")
Connect-SIOmdm | Out-Null
}
process
{
Get-mdmobjects -props "$Props" -objectid $VolumeID -objecttype VOLUME #-Verbose
}

end
{
}
}

function Get-SIOStoragePoolProperties 
{
[CmdletBinding()]
param (
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]$PoolID
)
begin 
{

[string]$Props = "CAPACITY_LIMIT_IN_KB
MAX_CAPACITY_IN_KB
CAPACITY_IN_USE_IN_KB
THICK_CAPACITY_IN_USE_IN_KB
THIN_CAPACITY_IN_USE_IN_KB
SNAP_CAPACITY_IN_USE_IN_KB
UNREACHABLE_UNUSED_CAPACITY_IN_KB
UNUSED_CAPACITY_IN_KB
SNAP_CAPACITY_IN_USE_OCCUPIED_IN_KB
THIN_CAPACITY_ALLOCATED_IN_KB
SPARE_CAPACITY_IN_KB
AVAILABLE_FOR_THICK_ALLOCATION_IN_KB
PROTECTED_CAPACITY_IN_KB
DEGRADED_HEALTHY_CAPACITY_IN_KB
DEGRADED_FAILED_CAPACITY_IN_KB
FAILED_CAPACITY_IN_KB
PROTECTED_VAC_IN_KB
DEGRADED_HEALTHY_VAC_IN_KB
DEGRADED_FAILED_VAC_IN_KB
FAILED_VAC_IN_KB
MOVING_CAPACITY_IN_KB
ACTIVE_MOVING_CAPACITY_IN_KB
PENDING_MOVING_CAPACITY_IN_KB
FWD_REBUILD_CAPACITY_IN_KB
ACTIVE_FWD_REBUILD_CAPACITY_IN_KB
PENDING_FWD_REBUILD_CAPACITY_IN_KB
BCK_REBUILD_CAPACITY_IN_KB
ACTIVE_BCK_REBUILD_CAPACITY_IN_KB
PENDING_BCK_REBUILD_CAPACITY_IN_KB
REBALANCE_CAPACITY_IN_KB
ACTIVE_REBALANCE_CAPACITY_IN_KB
PENDING_REBALANCE_CAPACITY_IN_KB
AT_REST_CAPACITY_IN_KB
ACTIVE_MOVING_IN_FWD_REBUILD_JOBS
ACTIVE_MOVING_IN_BCK_REBUILD_JOBS
ACTIVE_MOVING_IN_REBALANCE_JOBS
ACTIVE_MOVING_OUT_FWD_REBUILD_JOBS
ACTIVE_MOVING_OUT_BCK_REBUILD_JOBS
ACTIVE_MOVING_OUT_REBALANCE_JOBS
PENDING_MOVING_IN_FWD_REBUILD_JOBS
PENDING_MOVING_IN_BCK_REBUILD_JOBS
PENDING_MOVING_IN_REBALANCE_JOBS
PENDING_MOVING_OUT_FWD_REBUILD_JOBS
PENDING_MOVING_OUT_BCK_REBUILD_JOBS
PENDING_MOVING_OUT_REBALANCE_JOBS
IN_USE_VAC_IN_KB
PRIMARY_VAC_IN_KB
SECONDARY_VAC_IN_KB
FIXED_READ_ERROR_COUNT
PRIMARY_READ_BWC
PRIMARY_READ_FROM_DEV_BWC
PRIMARY_WRITE_BWC
SECONDARY_READ_BWC
SECONDARY_READ_FROM_DEV_BWC
SECONDARY_WRITE_BWC
FWD_REBUILD_READ_BWC
FWD_REBUILD_WRITE_BWC
BCK_REBUILD_READ_BWC
BCK_REBUILD_WRITE_BWC
REBALANCE_READ_BWC
REBALANCE_WRITE_BWC
TOTAL_READ_BWC
TOTAL_WRITE_BWC
USER_DATA_READ_BWC
USER_DATA_WRITE_BWC
NUM_OF_UNMAPPED_VOLUMES
NUM_OF_MAPPED_TO_ALL_VOLUMES
NUM_OF_THICK_BASE_VOLUMES
NUM_OF_THIN_BASE_VOLUMES
NUM_OF_SNAPSHOTS
NUM_OF_VOLUMES_IN_DELETION
DEVICE_ID_LIST
NUM_OF_DEVICES
VOLUME_ID_LIST
NUM_OF_VOLUMES
VTREE_ID_LIST
NUM_OF_VTREES
ID
NAME
SPARE_PERCENT
PROTECTION_DOMAIN_ID
ZERO_PAD_ENABLED
USE_RMCACHE
RMCACHE_WRITE_HANDLING_MODE
REBUILD_ENABLED
REBUILD_IO_PRIORITY_POLICY
NUM_REBUILD_IOPS_PER_DEVICE
REBUILD_BW_LIMIT_PER_DEVICE
REBUILD_APP_IOPS_PER_DEVICE_THRESHOLD
REBUILD_APP_BW_PER_DEVICE_THRESHOLD
REBUILD_QUIET_PERIOD
REBALANCE_ENABLED
REBALANCE_IO_PRIORITY_POLICY
NUM_REBALANCE_IOPS_PER_DEVICE
REBALANCE_BW_LIMIT_PER_DEVICE
REBALANCE_APP_IOPS_PER_DEVICE_THRESHOLD
REBALANCE_APP_BW_PER_DEVICE_THRESHOLD
REBALANCE_QUIET_PERIOD
NUM_PARALLEL_JOBS_PER_DEVICE"
$Props = $Props.Replace("`n",",")
$Props = $Props.Replace("`r","")
Connect-SIOmdm | Out-Null
}
process
{
Write-Verbose $PoolID
Get-mdmobjects -props "$Props" -objectid $PoolID -objecttype STORAGE_POOL # -Verbose
}

end
{
}
}



function Get-SIOSDSProperties 
{
[CmdletBinding()]
param (
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]$SDSID
)
begin 
{

[string]$Props = "CAPACITY_LIMIT_IN_KB
MAX_CAPACITY_IN_KB
CAPACITY_IN_USE_IN_KB
THICK_CAPACITY_IN_USE_IN_KB
THIN_CAPACITY_IN_USE_IN_KB
SNAP_CAPACITY_IN_USE_IN_KB
UNREACHABLE_UNUSED_CAPACITY_IN_KB
UNUSED_CAPACITY_IN_KB
SNAP_CAPACITY_IN_USE_OCCUPIED_IN_KB
THIN_CAPACITY_ALLOCATED_IN_KB
PROTECTED_VAC_IN_KB
DEGRADED_HEALTHY_VAC_IN_KB
DEGRADED_FAILED_VAC_IN_KB
FAILED_VAC_IN_KB
ACTIVE_MOVING_IN_FWD_REBUILD_JOBS
ACTIVE_MOVING_IN_BCK_REBUILD_JOBS
ACTIVE_MOVING_IN_REBALANCE_JOBS
ACTIVE_MOVING_OUT_FWD_REBUILD_JOBS
ACTIVE_MOVING_OUT_BCK_REBUILD_JOBS
ACTIVE_MOVING_OUT_REBALANCE_JOBS
PENDING_MOVING_IN_FWD_REBUILD_JOBS
PENDING_MOVING_IN_BCK_REBUILD_JOBS
PENDING_MOVING_IN_REBALANCE_JOBS
PENDING_MOVING_OUT_FWD_REBUILD_JOBS
PENDING_MOVING_OUT_BCK_REBUILD_JOBS
PENDING_MOVING_OUT_REBALANCE_JOBS
IN_USE_VAC_IN_KB
PRIMARY_VAC_IN_KB
SECONDARY_VAC_IN_KB
REBUILD_WAIT_SEND_Q_LENGTH
REBALANCE_WAIT_SEND_Q_LENGTH
REBUILD_PER_RECEIVE_JOB_NET_THROTTLING_IN_KBPS
REBALANCE_PER_RECEIVE_JOB_NET_THROTTLING_IN_KBPS
FIXED_READ_ERROR_COUNT
PRIMARY_READ_BWC
PRIMARY_READ_FROM_DEV_BWC
PRIMARY_WRITE_BWC
SECONDARY_READ_BWC
SECONDARY_READ_FROM_DEV_BWC
SECONDARY_WRITE_BWC
FWD_REBUILD_READ_BWC
FWD_REBUILD_WRITE_BWC
BCK_REBUILD_READ_BWC
BCK_REBUILD_WRITE_BWC
REBALANCE_READ_BWC
REBALANCE_WRITE_BWC
TOTAL_READ_BWC
TOTAL_WRITE_BWC
RMCACHE_SIZE_IN_KB
RMCACHE_SIZE_IN_USE_IN_KB
RMCACHE_ENTRY_EVICTION_SIZE_COUNT_IN_KB
RMCACHE_BIG_BLOCK_EVICTION_SIZE_COUNT_IN_KB
RMCACHE_NUM_OF_4KB_ENTRIES
RMCACHE_NUM_OF_8KB_ENTRIES
RMCACHE_NUM_OF_16KB_ENTRIES
RMCACHE_NUM_OF_32KB_ENTRIES
RMCACHE_NUM_OF_64KB_ENTRIES
RMCACHE_NUM_OF_128KB_ENTRIES
RMCACHE_4KB_ENTRY_COUNT
RMCACHE_8KB_ENTRY_COUNT
RMCACHE_16KB_ENTRY_COUNT
RMCACHE_32KB_ENTRY_COUNT
RMCACHE_64KB_ENTRY_COUNT
RMCACHE_128KB_ENTRY_COUNT
RMCACHE_ENTRY_EVICTION_COUNT
RMCACHE_BIG_BLOCK_EVICTION_COUNT
RMCACHE_NO_EVICTION_COUNT
RMCACHE_SKIP_COUNT_LARGE_IO
RMCACHE_SKIP_COUNT_UNALIGNED_4KB_IO
RMCACHE_SKIP_COUNT_CACHE_ALL_BUSY
DEVICE_ID_LIST
NUM_OF_DEVICES
ID
NAME
IPS
PORT
ON_VMWARE
PROTECTION_DOMAIN_ID
FAULT_SET_ID
STATE
MEMBERSHIP_STATE
MDM_CONNECTION_STATE
DRL_MODE
RMCACHE_ENABLED
RMCACHE_SIZE
RMCACHE_FROZEN
RMCACHE_MEMORY_ALLOCATION_STATE
NUMBER_OF_IO_BUFFERS"
$Props = $Props.Replace("`n",",")
$Props = $Props.Replace("`r","")
Connect-SIOmdm | Out-Null
}
process
{
Write-Verbose $SDSID
Get-mdmobjects -props "$Props" -objectid $SDSID -objecttype SDS # -Verbose
}

end
{
}
}


function Get-SIOSDCProperties 
{
[CmdletBinding()]
param (
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]$SDCID
)
begin 
{

[string]$Props = "USER_DATA_READ_BWC
USER_DATA_WRITE_BWC
VOLUME_ID_LIST
NUM_OF_MAPPED_VOLUMES
ID
NAME
GUID
IP
APPROVED
MDM_CONNECTION_STATE"
$Props = $Props.Replace("`n",",")
$Props = $Props.Replace("`r","")
Connect-SIOmdm | Out-Null
}
process
{
Write-Verbose $SDCID
Get-mdmobjects -props "$Props" -objectid $SDCID -objecttype SDC # -Verbose
}

end
{
}
}


function Get-SIOPDProperties 
{
[CmdletBinding()]
param (
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]$PDID
)
begin 
{

[string]$Props = "CAPACITY_LIMIT_IN_KB
MAX_CAPACITY_IN_KB
CAPACITY_IN_USE_IN_KB
THICK_CAPACITY_IN_USE_IN_KB
THIN_CAPACITY_IN_USE_IN_KB
SNAP_CAPACITY_IN_USE_IN_KB
UNREACHABLE_UNUSED_CAPACITY_IN_KB
UNUSED_CAPACITY_IN_KB
SNAP_CAPACITY_IN_USE_OCCUPIED_IN_KB
THIN_CAPACITY_ALLOCATED_IN_KB
SPARE_CAPACITY_IN_KB
AVAILABLE_FOR_THICK_ALLOCATION_IN_KB
PROTECTED_CAPACITY_IN_KB
DEGRADED_HEALTHY_CAPACITY_IN_KB
DEGRADED_FAILED_CAPACITY_IN_KB
FAILED_CAPACITY_IN_KB
PROTECTED_VAC_IN_KB
DEGRADED_HEALTHY_VAC_IN_KB
DEGRADED_FAILED_VAC_IN_KB
FAILED_VAC_IN_KB
MOVING_CAPACITY_IN_KB
ACTIVE_MOVING_CAPACITY_IN_KB
PENDING_MOVING_CAPACITY_IN_KB
FWD_REBUILD_CAPACITY_IN_KB
ACTIVE_FWD_REBUILD_CAPACITY_IN_KB
PENDING_FWD_REBUILD_CAPACITY_IN_KB
BCK_REBUILD_CAPACITY_IN_KB
ACTIVE_BCK_REBUILD_CAPACITY_IN_KB
PENDING_BCK_REBUILD_CAPACITY_IN_KB
REBALANCE_CAPACITY_IN_KB
ACTIVE_REBALANCE_CAPACITY_IN_KB
PENDING_REBALANCE_CAPACITY_IN_KB
AT_REST_CAPACITY_IN_KB
ACTIVE_MOVING_IN_FWD_REBUILD_JOBS
ACTIVE_MOVING_IN_BCK_REBUILD_JOBS
ACTIVE_MOVING_IN_REBALANCE_JOBS
ACTIVE_MOVING_OUT_FWD_REBUILD_JOBS
ACTIVE_MOVING_OUT_BCK_REBUILD_JOBS
ACTIVE_MOVING_OUT_REBALANCE_JOBS
PENDING_MOVING_IN_FWD_REBUILD_JOBS
PENDING_MOVING_IN_BCK_REBUILD_JOBS
PENDING_MOVING_IN_REBALANCE_JOBS
PENDING_MOVING_OUT_FWD_REBUILD_JOBS
PENDING_MOVING_OUT_BCK_REBUILD_JOBS
PENDING_MOVING_OUT_REBALANCE_JOBS
IN_USE_VAC_IN_KB
PRIMARY_VAC_IN_KB
SECONDARY_VAC_IN_KB
REBUILD_WAIT_SEND_Q_LENGTH
REBALANCE_WAIT_SEND_Q_LENGTH
REBUILD_PER_RECEIVE_JOB_NET_THROTTLING_IN_KBPS
REBALANCE_PER_RECEIVE_JOB_NET_THROTTLING_IN_KBPS
FIXED_READ_ERROR_COUNT
PRIMARY_READ_BWC
PRIMARY_READ_FROM_DEV_BWC
PRIMARY_WRITE_BWC
SECONDARY_READ_BWC
SECONDARY_READ_FROM_DEV_BWC
SECONDARY_WRITE_BWC
FWD_REBUILD_READ_BWC
FWD_REBUILD_WRITE_BWC
BCK_REBUILD_READ_BWC
BCK_REBUILD_WRITE_BWC
REBALANCE_READ_BWC
REBALANCE_WRITE_BWC
TOTAL_READ_BWC
TOTAL_WRITE_BWC
USER_DATA_READ_BWC
USER_DATA_WRITE_BWC
RMCACHE_SIZE_IN_KB
RMCACHE_SIZE_IN_USE_IN_KB
RMCACHE_ENTRY_EVICTION_SIZE_COUNT_IN_KB
RMCACHE_BIG_BLOCK_EVICTION_SIZE_COUNT_IN_KB
RMCACHE_NUM_OF_4KB_ENTRIES
RMCACHE_NUM_OF_8KB_ENTRIES
RMCACHE_NUM_OF_16KB_ENTRIES
RMCACHE_NUM_OF_32KB_ENTRIES
RMCACHE_NUM_OF_64KB_ENTRIES
RMCACHE_NUM_OF_128KB_ENTRIES
RMCACHE_4KB_ENTRY_COUNT
RMCACHE_8KB_ENTRY_COUNT
RMCACHE_16KB_ENTRY_COUNT
RMCACHE_32KB_ENTRY_COUNT
RMCACHE_64KB_ENTRY_COUNT
RMCACHE_128KB_ENTRY_COUNT
RMCACHE_ENTRY_EVICTION_COUNT
RMCACHE_BIG_BLOCK_EVICTION_COUNT
RMCACHE_NO_EVICTION_COUNT
RMCACHE_SKIP_COUNT_LARGE_IO
RMCACHE_SKIP_COUNT_UNALIGNED_4KB_IO
RMCACHE_SKIP_COUNT_CACHE_ALL_BUSY
NUM_OF_UNMAPPED_VOLUMES
NUM_OF_MAPPED_TO_ALL_VOLUMES
NUM_OF_THICK_BASE_VOLUMES
NUM_OF_THIN_BASE_VOLUMES
NUM_OF_SNAPSHOTS
NUM_OF_VOLUMES_IN_DELETION
SDS_ID_LIST
NUM_OF_SDS
STORAGE_POOL_ID_LIST
NUM_OF_STORAGE_POOLS
NUM_OF_FAULT_SETS
FAULT_SET_ID_LIST
ID
NAME
STATE
REBUILD_NETWORK_THROTTLING_ENABLED
REBALANCE_NETWORK_THROTTLING_ENABLED
OVERALL_IO_NETWORK_THROTTLING_ENABLED
REBUILD_NETWORK_THROTTLING
REBALANCE_NETWORK_THROTTLING
OVERALL_IO_NETWORK_THROTTLING"
$Props = $Props.Replace("`n",",")
$Props = $Props.Replace("`r","")
Connect-SIOmdm | Out-Null
}
process
{
Write-Verbose $PDID
Get-mdmobjects -props "$Props" -objectid $PDID -objecttype PROTECTION_DOMAIN # -Verbose
}

end
{
}
}




function Get-SIOVtreeProperties 
{
[CmdletBinding()]
param (
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]$VtreeID
)
begin 
{

[string]$Props = "NET_CAPACITY_IN_USE_IN_KB
BASE_NET_CAPACITY_IN_USE_IN_KB
SNAP_NET_CAPACITY_IN_USE_IN_KB
TRIMMED_CAPACITY_IN_KB
VOLUME_ID_LIST
NUM_OF_VOLUMES
ID
NAME
STORAGE_POOL_ID
BASE_VOLUME_ID"
$Props = $Props.Replace("`n",",")
$Props = $Props.Replace("`r","")
Connect-SIOmdm | Out-Null
}
process
{
Write-Verbose $VTREEID
Get-mdmobjects -props "$Props" -objectid $VtreeID -objecttype VTREE # -Verbose
}

end
{
}
}




function Get-SIOSystemProperties 
{
[CmdletBinding()]
param (
[Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]$SystemID
)
begin 
{

[string]$Props = "CAPACITY_LIMIT_IN_KB
MAX_CAPACITY_IN_KB
CAPACITY_IN_USE_IN_KB
THICK_CAPACITY_IN_USE_IN_KB
THIN_CAPACITY_IN_USE_IN_KB
SNAP_CAPACITY_IN_USE_IN_KB
UNREACHABLE_UNUSED_CAPACITY_IN_KB
UNUSED_CAPACITY_IN_KB
SNAP_CAPACITY_IN_USE_OCCUPIED_IN_KB
THIN_CAPACITY_ALLOCATED_IN_KB
SPARE_CAPACITY_IN_KB
AVAILABLE_FOR_THICK_ALLOCATION_IN_KB
PROTECTED_CAPACITY_IN_KB
DEGRADED_HEALTHY_CAPACITY_IN_KB
DEGRADED_FAILED_CAPACITY_IN_KB
FAILED_CAPACITY_IN_KB
PROTECTED_VAC_IN_KB
DEGRADED_HEALTHY_VAC_IN_KB
DEGRADED_FAILED_VAC_IN_KB
FAILED_VAC_IN_KB
MOVING_CAPACITY_IN_KB
ACTIVE_MOVING_CAPACITY_IN_KB
PENDING_MOVING_CAPACITY_IN_KB
FWD_REBUILD_CAPACITY_IN_KB
ACTIVE_FWD_REBUILD_CAPACITY_IN_KB
PENDING_FWD_REBUILD_CAPACITY_IN_KB
BCK_REBUILD_CAPACITY_IN_KB
ACTIVE_BCK_REBUILD_CAPACITY_IN_KB
PENDING_BCK_REBUILD_CAPACITY_IN_KB
REBALANCE_CAPACITY_IN_KB
ACTIVE_REBALANCE_CAPACITY_IN_KB
PENDING_REBALANCE_CAPACITY_IN_KB
AT_REST_CAPACITY_IN_KB
ACTIVE_MOVING_IN_FWD_REBUILD_JOBS
ACTIVE_MOVING_IN_BCK_REBUILD_JOBS
ACTIVE_MOVING_IN_REBALANCE_JOBS
ACTIVE_MOVING_OUT_FWD_REBUILD_JOBS
ACTIVE_MOVING_OUT_BCK_REBUILD_JOBS
ACTIVE_MOVING_OUT_REBALANCE_JOBS
PENDING_MOVING_IN_FWD_REBUILD_JOBS
PENDING_MOVING_IN_BCK_REBUILD_JOBS
PENDING_MOVING_IN_REBALANCE_JOBS
PENDING_MOVING_OUT_FWD_REBUILD_JOBS
PENDING_MOVING_OUT_BCK_REBUILD_JOBS
PENDING_MOVING_OUT_REBALANCE_JOBS
IN_USE_VAC_IN_KB
PRIMARY_VAC_IN_KB
SECONDARY_VAC_IN_KB
REBUILD_WAIT_SEND_Q_LENGTH
REBALANCE_WAIT_SEND_Q_LENGTH
REBUILD_PER_RECEIVE_JOB_NET_THROTTLING_IN_KBPS
REBALANCE_PER_RECEIVE_JOB_NET_THROTTLING_IN_KBPS
FIXED_READ_ERROR_COUNT
PRIMARY_READ_BWC
PRIMARY_READ_FROM_DEV_BWC
PRIMARY_WRITE_BWC
SECONDARY_READ_BWC
SECONDARY_READ_FROM_DEV_BWC
SECONDARY_WRITE_BWC
FWD_REBUILD_READ_BWC
FWD_REBUILD_WRITE_BWC
BCK_REBUILD_READ_BWC
BCK_REBUILD_WRITE_BWC
REBALANCE_READ_BWC
REBALANCE_WRITE_BWC
TOTAL_READ_BWC
TOTAL_WRITE_BWC
USER_DATA_READ_BWC
USER_DATA_WRITE_BWC
RMCACHE_SIZE_IN_KB
RMCACHE_SIZE_IN_USE_IN_KB
RMCACHE_ENTRY_EVICTION_SIZE_COUNT_IN_KB
RMCACHE_BIG_BLOCK_EVICTION_SIZE_COUNT_IN_KB
RMCACHE_NUM_OF_4KB_ENTRIES
RMCACHE_NUM_OF_8KB_ENTRIES
RMCACHE_NUM_OF_16KB_ENTRIES
RMCACHE_NUM_OF_32KB_ENTRIES
RMCACHE_NUM_OF_64KB_ENTRIES
RMCACHE_NUM_OF_128KB_ENTRIES
RMCACHE_4KB_ENTRY_COUNT
RMCACHE_8KB_ENTRY_COUNT
RMCACHE_16KB_ENTRY_COUNT
RMCACHE_32KB_ENTRY_COUNT
RMCACHE_64KB_ENTRY_COUNT
RMCACHE_128KB_ENTRY_COUNT
RMCACHE_ENTRY_EVICTION_COUNT
RMCACHE_BIG_BLOCK_EVICTION_COUNT
RMCACHE_NO_EVICTION_COUNT
RMCACHE_SKIP_COUNT_LARGE_IO
RMCACHE_SKIP_COUNT_UNALIGNED_4KB_IO
RMCACHE_SKIP_COUNT_CACHE_ALL_BUSY
NUM_OF_UNMAPPED_VOLUMES
NUM_OF_MAPPED_TO_ALL_VOLUMES
NUM_OF_THICK_BASE_VOLUMES
NUM_OF_THIN_BASE_VOLUMES
NUM_OF_SNAPSHOTS
NUM_OF_VOLUMES_IN_DELETION
NUM_OF_DEVICES
NUM_OF_SDS
NUM_OF_STORAGE_POOLS
NUM_OF_VOLUMES
NUM_OF_VTREES
SCSI_INITIATOR_ID_LIST
NUM_OF_SCSI_INITIATORS
PROTECTION_DOMAIN_ID_LIST
NUM_OF_PROTECTION_DOMAINS
SDC_ID_LIST
NUM_OF_SDC
NUM_OF_FAULT_SETS
ID
NAME
VERSION_NAME
DEFAULT_VOL_OBFUSCATION
CAPACITY_ALERT_HIGH_THRESHOLD
CAPACITY_ALERT_CRITICAL_THRESHOLD
INSTALL_ID
SW_ID
DAYS_INSTALLED
MAX_LICENSED_CAPACITY
CAPACITY_DAYS_LEFT
OBFUSCATION_DAYS_LEFT
SNAPSHOTS_DAYS_LEFT
QOS_DAYS_LEFT
REPLICATION_DAYS_LEFT
INITIAL_LICENSE
THICK_VOLUME_PERCENT
MDM_MODE
MDM_CLUSTER_STATE
PRIMARY_MDM_ACTOR_IPS
PRIMARY_MDM_ACTOR_PORT
SECONDARY_MDM_ACTOR_IPS
SECONDARY_MDM_ACTOR_PORT
TIEBREAKER_MDM_ACTOR_IPS
TIEBREAKER_MDM_ACTOR_PORT
MDM_MGMT_IPS
MDM_MGMT_PORT
RESTRICETED_SDC_MODE_ENABLED"
$Props = $Props.Replace("`n",",")
$Props = $Props.Replace("`r","")
Connect-SIOmdm | Out-Null
}
process
{
Write-Verbose $SystemID
Get-mdmobjects -props "$Props" -objectid $SystemID -objecttype SYSTEM # -Verbose
}

end
{
}
}



function Get-SIODeviceProperties 
{
[CmdletBinding()]
param (
[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")][string]$SIODeviceID
)
begin 
{

[string]$Props = "CAPACITY_LIMIT_IN_KB
MAX_CAPACITY_IN_KB
CAPACITY_IN_USE_IN_KB
THICK_CAPACITY_IN_USE_IN_KB
THIN_CAPACITY_IN_USE_IN_KB
SNAP_CAPACITY_IN_USE_IN_KB
UNREACHABLE_UNUSED_CAPACITY_IN_KB
UNUSED_CAPACITY_IN_KB
SNAP_CAPACITY_IN_USE_OCCUPIED_IN_KB
THIN_CAPACITY_ALLOCATED_IN_KB
PROTECTED_VAC_IN_KB
DEGRADED_HEALTHY_VAC_IN_KB
DEGRADED_FAILED_VAC_IN_KB
FAILED_VAC_IN_KB
ACTIVE_MOVING_IN_FWD_REBUILD_JOBS
ACTIVE_MOVING_IN_BCK_REBUILD_JOBS
ACTIVE_MOVING_IN_REBALANCE_JOBS
ACTIVE_MOVING_OUT_FWD_REBUILD_JOBS
ACTIVE_MOVING_OUT_BCK_REBUILD_JOBS
ACTIVE_MOVING_OUT_REBALANCE_JOBS
PENDING_MOVING_IN_FWD_REBUILD_JOBS
PENDING_MOVING_IN_BCK_REBUILD_JOBS
PENDING_MOVING_IN_REBALANCE_JOBS
PENDING_MOVING_OUT_FWD_REBUILD_JOBS
PENDING_MOVING_OUT_BCK_REBUILD_JOBS
PENDING_MOVING_OUT_REBALANCE_JOBS
IN_USE_VAC_IN_KB
PRIMARY_VAC_IN_KB
SECONDARY_VAC_IN_KB
FIXED_READ_ERROR_COUNT
PRIMARY_READ_BWC
PRIMARY_READ_FROM_DEV_BWC
PRIMARY_WRITE_BWC
SECONDARY_READ_BWC
SECONDARY_READ_FROM_DEV_BWC
SECONDARY_WRITE_BWC
FWD_REBUILD_READ_BWC
FWD_REBUILD_WRITE_BWC
BCK_REBUILD_READ_BWC
BCK_REBUILD_WRITE_BWC
REBALANCE_READ_BWC
REBALANCE_WRITE_BWC
TOTAL_READ_BWC
TOTAL_WRITE_BWC
AVG_READ_SIZE_IN_BYTES
AVG_WRITE_SIZE_IN_BYTES
AVG_READ_LATENCY_IN_MICROSEC
AVG_WRITE_LATENCY_IN_MICROSEC
ID
NAME
CURRENT_PATH
ORIGINAL_PATH
STATE
ERR_STATE
CAPACITY_LIMIT
MAX_CAPACITY
SDS_ID
STORAGE_POOL_ID"
$Props = $Props.Replace("`n",",")
$Props = $Props.Replace("`r","")
Connect-SIOmdm | Out-Null
}
process
{
Write-Verbose $SIODeviceID
Get-mdmobjects -props "$Props" -objectid $SIODeviceID -objecttype DEVICE # -Verbose
}

end
{
}
}

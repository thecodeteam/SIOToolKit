$Field1 = "Name: "
$PoolPattern = "Storage Pool "
$PDPattern = "Protection Domain "
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
function Get-SIOPools
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
function Get-SIOVolumes
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
        [Alias("ID")] 
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
                $Volumequery = scli --query_volume --volume_id $VolumeID --mdm_ip $Global:mdm  2> $null
                }
            "2"
                {
                $Volumequery = scli --query_volume --volume_name $VolumeName --mdm_ip $Global:mdm  2> $null
                }
            }
        If ($LASTEXITCODE -eq 0)
            {
            if ($Volumequery -match "Mapped SDSs:")
                {
                Write-Verbose "Volume is multimapped"
                [bool]$MultiMapped = $true
            }
            if ($Volumequery -match "SDS ID:")
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
        ### Volume ####
        
        $IDTag = ">> Volume ID: "
        $Convert = Convert-line -Value ($Volumequery | where {$_ -match $IDTag}) -Field1 $Field1 -IDTag $IDTag
        $Object | Add-Member -MemberType NoteProperty -Name VolumeName -Value $Convert.Field1
        $Object | Add-Member -MemberType NoteProperty -Name VolumeID -Value $Convert.id
        $Object | Add-Member -MemberType NoteProperty -Name Type -Value $Type
        $object | Add-Member -MemberType NoteProperty -Name Mapped -Value $Mapped
        $object | Add-Member -MemberType NoteProperty -Name MultiMapped -Value $MultiMapped


        #### Pool   ####
        $IDTag = "   Storage Pool "
        $Convert = Convert-line -Value ($Volumequery | where {$_ -match $IDTag}) -Field1 $Field1 -IDTag $IDTag
        $Object | Add-Member -MemberType NoteProperty -Name Pool -Value $Convert.Field1
        $Object | Add-Member -MemberType NoteProperty -Name PoolID -Value $Convert.id

        #### Protection Domain   ####
        $IDTag = "   Protection Domain "
        $Convert = Convert-line -Value ($Volumequery | where {$_ -match $IDTag}) -Field1 $Field1 -IDTag $IDTag
        $Object | Add-Member -MemberType NoteProperty -Name ProtectionDomain -Value $Convert.Field1
        $Object | Add-Member -MemberType NoteProperty -Name PDid -Value $Convert.id
        #####Mapped SDS
        if ($Mapped)
            {
            $SDSout = @()
            $IDTag = "      SDS ID: "
            $Field2 = "IP: "
            write-verbose "testing SDS´s"
            $SDSlist = $Volumequery | where {$_ -match $IDTag}
            foreach ($SDS in $SDSlist)
                {
                $SDSobject = New-Object -TypeName psobject
                $Convert = Convert-line -Value $SDS -Field1 $Field1 -IDTag $IDTag -Field2 $Field2
                $SDSObject | Add-Member -MemberType NoteProperty -Name SDSID -Value $Convert.id
                $SDSObject | Add-Member -MemberType NoteProperty -Name IPAddress -Value $Convert.Field1
                $SDSObject | Add-Member -MemberType NoteProperty -Name VolumeName -Value $convert.Field2
                $SDSout += $SDSobject
                }
            
            $Object | Add-Member -MemberType NoteProperty -Name SDS -Value $SDSout

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


#SDS ID: 0430f6b000000000 Name: hvnode1 IP: 192.168.2.151 State: Connected GUID: 7202918A-5010-154E-A51E-032A73F2CDC2#
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
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
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
                $SDSquery = scli --query_SDS --SDS_id $SDSID --mdm_ip $Global:mdm 2> $sclierror
                    
                }
            "2"
                {
                $SDSquery = scli --query_SDS --SDS_name $SDSName --mdm_ip $Global:mdm 2> $sclierror
                }
        }
        
        
        If ($LASTEXITCODE -eq 0)
            { 
            if ($SDSquery -match "SDS ID:")
                {
                    $currentSDS = $SDSquery.Replace("SDS ID: ","")
                    $currentSDS = $currentSDS.Replace(" Name:","")
                    $currentSDS = $currentSDS.Replace(" IP:","")
                    $currentSDS = $currentSDS.Replace(" State:","")
                    $currentSDS = $currentSDS.Replace(" GUID:","")
                    $currentSDS = $currentSDS.SPlit(' ')
                    $CurrentSDSname = $currentSDS[1]
                    $CurrentSDSID = $currentSDS[0]
                    $CurrentSDSIP = $currentSDS[2]
                    $CurrentSDSState = $currentSDS[3]
                    $CurrentSDSGuid = $currentSDS[4]
                    Write-Verbose "Found SDS $SDS"
                    $object = New-Object -TypeName psobject
		            $Object | Add-Member -MemberType NoteProperty -Name SDSName -Value $CurrentSDSname
		            $object | Add-Member -MemberType NoteProperty -Name SDSID -Value $CurrentSDSID
		            $object | Add-Member -MemberType NoteProperty -Name IP -Value $CurrentSDSIP
		            $Object | Add-Member -MemberType NoteProperty -Name State -Value $CurrentSDSState
		            $object | Add-Member -MemberType NoteProperty -Name GUID -Value $CurrentSDSGuid
                    Write-Output $object
                }

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
        $LASTEXITCODE
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
                    Write-Verbose "Found SDS $SDS"
                    $object = New-Object -TypeName psobject
		            $Object | Add-Member -MemberType NoteProperty -Name SDSName -Value $CurrentSDSname
		            $object | Add-Member -MemberType NoteProperty -Name SDSID -Value $CurrentSDSID
		            $object | Add-Member -MemberType NoteProperty -Name PDName -Value $CurrentPDname
		            $Object | Add-Member -MemberType NoteProperty -Name PDID -Value $CurrentPDID
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
[Alias("ID")]
$SDCID,
# Specify the SIO SDC Name
[Parameter(Mandatory=$true,
ValueFromPipelineByPropertyName=$true,
ParameterSetName='2')]
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]
[Alias("Name")]
$SDCName
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
$object | Add-Member -MemberType NoteProperty -Name ID -Value $CurrentsdcID
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
		            $object | Add-Member -MemberType NoteProperty -Name ID -Value $CurrentSDCID
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
    # Specify the New Volume Name  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false,ParameterSetName='1')][Alias("VN")]$VolumeName,
    # Specify if thin, default thick  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$false,ParameterSetName='1')][switch]$Thin,
    # Specify the New Volume Size in GB 
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$false,ParameterSetName='1')][ValidateRange(1,64000)]$SizeInGB



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
                        $Object | Add-Member -MemberType NoteProperty -Name "$objecttype$Property" -Value $Value
                        }
                    }
                }
    
            }
    Write-Output $object
}
}

function Get-SIOvolumeproperties 
{
[CmdletBinding()]
param (
[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]
[validateLength(16,16)][ValidatePattern("[0-9A-F]{16}")]$VolumeID
)
begin 
{
[string]$Props = "USER_DATA_READ_BWC,USER_DATA_WRITE_BWC
CHILD_VOLUME_ID_LIST
NUM_OF_CHILD_VOLUMES
DESCENDANT_VOLUME_ID_LIST
NUM_OF_DESCENDANT_VOLUMES
NUM_OF_MAPPED_SDSS
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
MAPPING_TO_ALL_SDSS_ENABLED
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

function Get-SIOPoolProperties 
{
[CmdletBinding()]
param (
[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]
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
[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]
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
[Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]
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
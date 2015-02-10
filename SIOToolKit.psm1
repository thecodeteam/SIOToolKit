$Field1 = "Name: "

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
$cmdresult = scli --mdm_ip $Global:mdm --login --username $Global:siousername --password $Global:siopassword 2>&1 
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



function get-yesno
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
        if ($pscmdlet.ShouldProcess("Target", "Operation"))
        {
        $Volumes = scli --query_all_volumes --mdm_ip $Global:mdm


        foreach ($Volume in $Volumes )
            {
            # find pool in volumelist
            [bool]$Mapped = $false
            if ($Volume -match "Storage Pool")
                {
                    $currentpool = $Volume.Replace("Storage Pool ","")
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
		        $Object | Add-Member -MemberType NoteProperty -Name Name -Value $currentvolumename
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
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
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
                $Volumequery = scli --query_volume --volume_id $VolumeID --mdm_ip $Global:mdm
                }
            "2"
                {
                $Volumequery = scli --query_volume --volume_name $VolumeName --mdm_ip $Global:mdm
                }
            }
        
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
        ### Volume ####
        $IDTag = ">> Volume ID: "
        $Convert = Convert-line -Value ($Volumequery | where {$_ -match $IDTag}) -Field1 $Field1 -IDTag $IDTag
        $Object | Add-Member -MemberType NoteProperty -Name Name -Value $Convert.Field1
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
        #####Mapped SDC
        if ($Mapped)
            {
            $SDCout = @()
            $IDTag = "      SDC ID: "
            $Field2 = "IP: "
            write-verbose "testing SDC´s"
            $SDClist = $Volumequery | where {$_ -match $IDTag}
            foreach ($SDC in $SDClist)
                {
                $SDCobject = New-Object -TypeName psobject
                $Convert = Convert-line -Value $sdc -Field1 $Field1 -IDTag $IDTag -Field2 $Field2
                $SDCObject | Add-Member -MemberType NoteProperty -Name SDCID -Value $Convert.id
                $SDCObject | Add-Member -MemberType NoteProperty -Name IPAddress -Value $Convert.Field1
                $SDCObject | Add-Member -MemberType NoteProperty -Name Name -Value $convert.Field2
                $SDCout += $SDCobject
                }
            
            $Object | Add-Member -MemberType NoteProperty -Name SDC -Value $SDCout

            }
        Write-Output $object
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
function Get-SIOSDCs
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
        if ($pscmdlet.ShouldProcess("Target", "Operation"))
        {
        $SDCS = scli --query_all_sdc --mdm_ip $Global:mdm


        foreach ($SDC in $SDCS )
            {
            
            if ($SDC -match "SDC ID:")
                {
                    $currentsdc = $SDC.Replace("SDC ID: ","")
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
		            $Object | Add-Member -MemberType NoteProperty -Name Name -Value $Currentsdcname
		            $object | Add-Member -MemberType NoteProperty -Name ID -Value $CurrentsdcID
		            $object | Add-Member -MemberType NoteProperty -Name IP -Value $CurrentsdcIP
		            $Object | Add-Member -MemberType NoteProperty -Name State -Value $CurrentsdcState
		            $object | Add-Member -MemberType NoteProperty -Name GUID -Value $CurrentsdcGuid
                    Write-Output $object
                }


            }
#>

        }
    }
    End
    {
     }

}




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
    # Specify the SIO Volume ID  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]$VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')][Alias("VolumeName")]$Name
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
                $Volumequery = Get-SIOVolume -VolumeName $Name
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
        $commit = get-yesno -title "Commit Volume Unmap" -message "This will unmap the above Volume from all Hosts"
        }
    Switch ($commit)
        {
            1
            {
            scli --unmap_volume_from_sdc --volume_id $($Volumequery.Volumeid) --all_sdcs --i_am_sure --mdm_ip $mdm
            }
        }
    } 
}
end {}
}


function Connect-SIOVolume
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
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]$VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')][Alias("VolumeName")]$Name,
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]$SDCid
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
                    
                }
            "2"
                {
                $Volumequery = Get-SIOVolume -VolumeName $Name
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
    scli --map_volume_to_sdc --volume_id $($Volumequery.VolumeId) --sdc_id $SDCid --allow_multi_map --mdm_ip $mdm
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
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]$VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')][Alias("VolumeName")]$Name
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
                $Volumequery = Get-SIOVolume -VolumeName $Name
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
        $commit = get-yesno -title "Commit Volume Deletion" -message "This will delete the above Volume"
        }
    Switch ($commit)
        {
            1
            {
            scli --remove_volume --volume_id $($Volumequery.VolumeID) --i_am_sure --mdm_ip $mdm
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

function Remove-SIOSnaphotTree
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
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]$VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')][Alias("VolumeName")]$Name
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
                $Volumequery = Get-SIOVolume -VolumeName $Name
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
    scli --remove_volume --volume_id $($Volumequery.VolumeID) --i_am_sure --mdm_ip $mdm
    } 
}
end {}
}
#>

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
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]$VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')][Alias("VolumeName")]$Name


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
                $Volumequery = Get-SIOVolume -VolumeName $Name
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
        $commit = get-yesno -title "Commit Snapshot Deletion" -message "This will delete the Entire Tree including the above Volume"
        }
    Switch ($commit)
        {
            1
            {
            scli --remove_volume --volume_id $($Volumequery.VolumeID) --i_am_sure --remove_entire_snapshot_tree --mdm_ip $mdm
            }
        }
    } 
}
end {}
}

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
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]$VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')][Alias("VolumeName")]$Name
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
                $Volumequery = Get-SIOVolume -VolumeName $Name
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
        $commit = get-yesno -title "Commit Snapshot Deletion" -message "This will delete the Entire Snapshot Tree of the above Volume"
        }
    Switch ($commit)
        {
            1
            {
            scli --remove_volume --volume_id $($Volumequery.VolumeID) --i_am_sure --remove_descendant_snapshots_only --mdm_ip $mdm
            }
        }
    } 
}
end {}
}

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
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]$VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')][Alias("VolumeName")]$Name
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
                $Volumequery = Get-SIOVolume -VolumeName $Name
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
        $commit = get-yesno -title "Commit Snapshot Deletion" -message "This will delete the Entire Snapshot Tree of the above Volume Including Parents"
        }
    Switch ($commit)
        {
            1
            {
            scli --remove_volume --volume_id $($Volumequery.VolumeID) --i_am_sure --remove_with_descendant_snapshots --mdm_ip $mdm
            }
        }
    } 
}
end {}
}

#scli --snapshot_volume --volume_id ($Snapsource -Join ',') --snapshot_name ($Snaptarget -Join ',') --mdm_ip $mdm
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
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("ID")]$VolumeID,
    # Specify the SIO Volume Name  
        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,ParameterSetName='2')][Alias("VolumeName")]$Name
    )#end param
begin 
{
$Snapsource = @()
$Snaptarget = @()
$Snapname = get-date -Format hhmmss$Congroup = $false

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
                $Volumequery = Get-SIOVolume -VolumeName $Name
                }
     }
if (!($Volumequery))
    {
    write-error "Volume $VolumeID $VolumeName not found"
    Break
    }
Else
    {
    $Snapsource += $Volumequery.VolumeId
    $Snaptarget += "$($Volumequery.Name.Substring(0,5))_$Snapname"
        } 
}
end {
    write-verbose ($Snapsource -Join ',')
    $Snapshots = scli --snapshot_volume --volume_id ($Snapsource -Join ',') --snapshot_name ($Snaptarget -Join ',') --mdm_ip $mdm
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


# scli --query_cluster --mdm_ip $mdm



<#
Usage: scli --add_volume (((--protection_domain_id <ID> | --protection_domain_name <NAME>) [--storage_pool_name <NAME>])
 | --storage_pool_id <ID>) --size_gb <SIZE> [--volume_name <NAME>] [Options] [Obfuscation Options] [Use RAM Read Cache O
ptions]
Description: Add a volume
Parameters:
    --protection_domain_id <ID>         Protection Domain ID
    --protection_domain_name <NAME>     Protection Domain name
    --storage_pool_id <ID>              Storage Pool ID
    --storage_pool_name <NAME>          Storage Pool name
    --size_gb <SIZE>                    Volume size in GB. Basic allocation granularity is 8 GB
    --volume_name <NAME>                Name to be assigned to the added volume
    Provisioning options: CHOOSE ONE
    --thin_provisioned                  This volume will be thin-provisioned
    --thick_provisioned                 This volume will be thick-provisioned
    <blank>                             Use default (thick provisioned)
    Obfuscation Options: CHOOSE ONE
    --use_obfuscation                   Obfuscate the data of this volume.  This overrides the global obfuscation defaul
t
    --dont_use_obfuscation              Do not obfuscate the data of this volume.  This overrides the global obfuscation
 default
    <blank>                             Use global obfuscation default
    Use RAM Read Cache Options: CHOOSE ONE
    --use_rmcache                       Use RAM Read Cache for devices in the Storage Pool
    --dont_use_rmcache                  Do not use RAM Read Cache for the devices in Storage Pool
    <blank>                             Use default (use_rmcache)



#>


#scli --snapshot_volume --volume_id ($Snapsource -Join ',') --snapshot_name ($Snaptarget -Join ',') --mdm_ip $mdm
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
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("PDN")]$PDName,
    # Specify the SIO Pool Name  
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName='1')][Alias("SPN")]$SPName,
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
                write-verbose "scli --add_volume --protection_domain_name $PDName --storage_pool_name $SPName --size_gb $SizeInGB $Extraparam --mdm_ip $mdm"
                If ($VolumeName)
                    {
                    $Newvol = scli --add_volume --protection_domain_name $PDName --storage_pool_name $SPName --size_gb $SizeInGB --volume_name $VolumeName $Extraparam --mdm_ip $mdm 
                    }
                else
                    {
                    $Newvol = scli --add_volume --protection_domain_name $PDName --storage_pool_name $SPName --size_gb $SizeInGB $Extraparam --mdm_ip $mdm 
                    }

               # scli --add_volume --protection_domain_name $PDName --storage_pool_name $SPName --size_gb $SizeInGB $VolNameparam $Thinparam  --mdm_ip "$mdm"
                    
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
           <# $object = New-Object -TypeName psobject
            $Object | Add-Member -MemberType NoteProperty -Name SourceID $Snappair[0]
            $Object | Add-Member -MemberType NoteProperty -Name SnapID -Value $Snappair[1]
            $Object | Add-Member -MemberType NoteProperty -Name Snapname -Value $Snappair[2]
            $Object | Add-Member -MemberType NoteProperty -Name Congroup -Value $HasConGroup
            $Object | Add-Member -MemberType NoteProperty -Name CongroupID -Value $ConGroupid
            Write-Output $object #>
            }   
        }
  
}

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

$Field1 = "Name: "
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

#function to unamp from SDC
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
    scli --unmap_volume_from_sdc --volume_name $($Volumequery.name) --all_sdcs --i_am_sure --mdm_ip $mdm
    } 
        


}

}
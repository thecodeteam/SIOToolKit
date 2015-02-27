SIOToolKit
==========


SIOToolKit is a Powershell wrapper for ScaleIO scli

SIOToolKit only requires cli.exe in the modulepath if not running on an mdm

SIOToolKit is community-driven

for wishes and comments post an anwers to https://community.emc.com/blogs/bottk/2015/02/08/siotoolkit-hello-world

simply follow @hyperv_guy for updates

current exposed commands
===========
```PowerShell
CommandType     Name                                               ModuleName
-----------     ----                                               ----------
Function        Connect-SIOmdm                                     SIOToolKit
Function        Connect-SIOVolume                                  SIOToolKit
Function        Disconnect-SIOVolume                               SIOToolKit
Function        Get-SIOPDProperties                                SIOToolKit
Function        Get-SIOPoolProperties                              SIOToolKit
Function        Get-SIOSDC                                         SIOToolKit
Function        Get-SIOSDCProperties                               SIOToolKit
Function        Get-SIOSDS                                         SIOToolKit
Function        Get-SIOSDSProperties                               SIOToolKit
Function        Get-SIOVolume                                      SIOToolKit
Function        Get-SIOVolumeProperties                            SIOToolKit
Function        New-SIOSnapshot                                    SIOToolKit
Function        New-SIOVolume                                      SIOToolKit
Function        Remove-SIOSnapshotTree                             SIOToolKit
Function        Remove-SIOSnapshotTreewithParents                  SIOToolKit
Function        Remove-SIOVolume                                   SIOToolKit
Function        Remove-SIOVolumeTree                               SIOToolKit
Function        Show-SIOPools                                      SIOToolKit
Function        Show-SIOSDCs                                       SIOToolKit
Function        Show-SIOSDSs                                       SIOToolKit
Function        Show-SIOVolumes                                    SIOToolKit
```
Installation
===========
If 
installing on an mdm where scli/mdm is present:
Extract the SIOToolkit to the Modules Path or any other path on the MDM.
Import the Module into Powershell


elseif
If installing Windows Machine where no scli is present:
Extract the SIOToolkit to the Modules Path or any other path.
Copy cli.exe from an MDM/Windows Installation to the Modulkes Directory ( not part of the Modules )


Import the Module into Powershell
```PowerShell
import-module SIOToolKit
```

Examples
===========
```PowerShell
# import the moduel. first time load in a session requires mdm ip and user / password
impo SIOToolKit # if not in the modules path, specify a path
# Example with Path:
Windows PowerShell
Copyright (C) 2014 Microsoft Corporation. All rights reserved.

PS C:\Users\Administrator.labbuildr> ipmo "\\vmware-host\shared folders\SWDIST\GIT\SIOToolKit"
Enter IP for MDM1: : 192.168.2.151
Enter IP for MDM2: : 192.168.2.152
Enter MDM Username: : admin
Enter MDM Password: : ************
VERBOSE: Connecting to MDM 192.168.2.151,192.168.2.152
# the Password is stored as a secure string in Memory

```
```PowerShell
# Get all SDC´s
Get-SIOSDCs
# Example
get-SIOSDCs | ft  -AutoSize

Name     ID               IP            State        GUID
----     --               --            -----        ----
hvnode1  0430f6b000000000 192.168.2.151 Connected    7202918A-5010-154E-A51E-032A73F2CDC2
hvnode2  0430f6b100000001 192.168.2.152 Connected    E42882C4-1FA6-A541-9830-3BEA0BF7D441
hvnode3  0430f6b200000002 192.168.2.153 Connected    0F1CE211-C1D0-154F-83A6-202B7F7D1927
nwserver 043144d100000003 192.168.2.1   Disconnected 9191C277-9A12-0341-9148-A8E51AF5EB3E
N/A      04316be000000004 192.168.2.10  Connected    DB01FFD1-A014-6047-AF57-BECACADA3E70

# get all volumes
Get-SIOVolumes | ft -AutoSize

Name         SizeGB Type     VolumeID         Pool         PoolID           Mapped
----         ------ ----     --------         ----         ------           ------
Vol_1        24.0   Thin     153ecca200000000 SP_labbuildr dcac7de400000001   True
Vol_1_051119 24.0   Snapshot 153fb72600000005 SP_labbuildr dcac7de400000001  False
Vol_2        24.0   Thin     153ecca300000001 SP_labbuildr dcac7de400000001   True
Vol_2_051119 24.0   Snapshot 153fb72700000006 SP_labbuildr dcac7de400000001  False
Vol_3        24.0   Thin     153ecca400000002 SP_labbuildr dcac7de400000001   True
Vol_3_051119 24.0   Snapshot 153fb72800000007 SP_labbuildr dcac7de400000001  False
Test1        24.0   Thin     153fb72400000003 SP_labbuildr dcac7de400000001  False


# get a speficic Volume
SYNTAX
    Get-SIOVolume -VolumeID <Object> [-WhatIf] [-Confirm]  [<CommonParameters>]

    Get-SIOVolume -VolumeName <Object> [-WhatIf] [-Confirm]  [<CommonParameters>]
#Example
Get-SIOVolume -VolumeName Vol_1


Name             : Vol_1
VolumeID         : 153ecca200000000
Type             : Thin
Mapped           : True
MultiMapped      : True
Pool             : SP_labbuildr
PoolID           : dcac7de400000001
ProtectionDomain : PD_labbuildr
PDid             : d094554b00000000
SDC              : {@{SDCID=0430f6b200000002; IPAddress=192.168.2.153; Name=hvnode3}, @{SDCID=0430f6b100000001;
                   IPAddress=192.168.2.152; Name=hvnode2}, @{SDCID=0430f6b000000000; IPAddress=192.168.2.151;
                   Name=hvnode1}}
```
Help
==========
while commands are self explaining, there is an online help available get-help [command]
Contributing
==========
Please contribute in any way to the project. Specifically, normalizing differnet image sizes, locations, and intance types would be easy adds to enhance the usefulness of the project.

Licensing
==========
Licensed under the Apache License, Version 2.0 (the “License”); you may not use this file except in compliance with the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

Support
==========
Please file bugs and issues at the Github issues page. The code and documentation are released with no warranties or SLAs and are intended to be supported through a community driven process.

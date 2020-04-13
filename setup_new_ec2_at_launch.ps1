#---Powershell script below

#setup_new_ec2_at_launch.ps1
#Author: 


# Steps taken:
#Resync Clock, Partition/Mount Drive, Copy S3 files to new drive, Install Applications, Firewall Rules, Create Hostname, Create NAME Tag for Ec2, 
# Schd-Task for reboot script,  Credentials Object for Domain Join, Rename Computer & Join Domain, Restart.
Start-Transcript -Path "C:\transcript_file_setup_ps.txt" -Force -Append
Try {
  #Update below for Role and Environment (P=Production, S=Beta, Q=QA, D=Development)
  #$Role = "WEB"
  #$Env = "P"
  #$keyprefix = $role.ToLower()+"/c"+$Env.ToLower()
  $keyprefix = "terraform/bootstrap"
  #$maintwindow = "None"
  #$costcenter = "Survey-Systems"

  #Resync the servers time
  W32tm /resync /force

  # Partition, Format, Name and mount D: drive
  Get-Disk |
  Where-Object partitionstyle -eq 'raw' |
  Initialize-Disk -PartitionStyle MBR -PassThru |
  New-Partition -AssignDriveLetter -UseMaximumSize |
  Format-Volume -FileSystem NTFS -NewFileSystemLabel "Encrypted" -Confirm:$false

  # Copy from S3 the files needed to D: drive
  Copy-S3Object -Region us-east-1 -BucketName ec2-launch -KeyPrefix $keyprefix -Folder d:\


  # Install Applications
  #Start-Process 'd:\Support\VC2017_redist.x64.exe' -ArgumentList "/s" -Wait
  #Start-Process 'd:\Support\npp.7.5.6.Installer.x64.exe' -ArgumentList "/S" -Wait 
  #Start-Process 'd:\Support\HeidiSQL_9.4.0.5125_Setup.exe' -ArgumentList "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP" -Wait
  #Start-Process 'd:\Support\AWSCLI64.msi' -ArgumentList "/quiet" -Wait
  #Start-Process 'd:\Support\rktools.msi' -ArgumentList "/Qb" -Wait #Used to get ntrights to set datahostdfs to Batch Job Rights

  #Install Chocolatey Package Provider
  Set-ExecutionPolicy Bypass -Scope Process -Force; `
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

  Install-PackageProvider -Name "chocolatey" -force

  #Install Additional applications
  $command = "choco install awscli -Y"
  invoke-expression -command $command

  $command = "choco install python3 -Y"
  invoke-expression -command $command

  
  #Sleep for a few seconds to let things catch up.
  Start-Sleep -Seconds 5



  #Create Firewall Rules to allow file sharing.

  New-NetFirewallRule -DisplayName "File and Printer Sharing 1 of 2" -Direction Inbound -Profile Domain -LocalPort 139, 445 -Protocol TCP -Action Allow
  New-NetFirewallRule -DisplayName "File and Printer Sharing 2 of 2" -Direction Inbound -Profile Domain -LocalPort 137, 138 -Protocol UDP -Action Allow


  #Function used to generate the unique Hostname.
  #Not needed, Gregs Terraform script names the EC2, but doesnt name the Hostname in the machine. That needs to be scripted here.

  <#
function convertTo-Base36
{
    [CmdletBinding()]
    param ([parameter(valuefrompipeline=$true, HelpMessage="Integer number to convert")][int64]$decNum="")
    $alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    do
    {
        $remainder = ($decNum % 36)
        $char = $alphabet.substring($remainder,1)
        $base36Num = "$char$base36Num"
        $decNum = ($decNum - $remainder) / 36
    }
    while ($decNum -gt 0)

    $base36Num
}

$StartDate = new-object System.DateTime 2000, 1, 1, 1, 1, 1
$EndDate = Get-Date
$SDays = New-TimeSpan -Start $StartDate -End $EndDate | Select-Object Days

$Days = ([math]::Round($SDays.Days))
$Days = $Days % 46656
$Days36 = convertTo-Base36 $Days

$MidNight=(Get-Date  -hour 0 -minute 0 -second 0)
$EndDate = Get-Date
$SSM = New-TimeSpan -Start $MidNight -End (Get-Date) | Select-Object Ticks
$Ticks = $SSM.Ticks

#Start of new section
$env:HostIP = (`Get-NetIPConfiguration | `
Where-Object { `
$_.IPv4DefaultGateway -ne $null `
-and `
$_.NetAdapter.Status -ne "Disconnected" `
} `
).IPv4Address.IPAddress.Replace('.','')

#$Ticks=$Ticks+[int64]$env:HostIP  #Line below replaces this one

$Ticks=$SSM.Ticks+[int64]$env:HostIP 
# End of New Section

$Ticks36 = convertTo-Base36 $Ticks


$Days36S = [string]($Days36)
$Ticks36S = [string]($Ticks36)

$FDays36S = "{0,3}" -f $Days36S
$FTicks36S = "{0,8}" -f $Ticks36S

$HostName=$Role.ToUpper() +$Env.ToUpper()+$FDays36S.Replace(' ','0')+$FTicks36S.Replace(' ','0')
#>


  #Create the EC2 TAGS for "Name" and "Maint-Window" Tags.
  ##Not needed, handled in Gregs Terraform script.
  <#
$tag = New-Object Amazon.EC2.Model.Tag
$tag.Key = "Name"
$tag.Value = $HostName
$tag2 = New-Object Amazon.EC2.Model.Tag
$tag2.Key = "Maint-Window"
$tag2.Value = $maintwindow
$tag3 = New-Object Amazon.EC2.Model.Tag
$tag3.Key = "cost-center"
$tag3.Value = $costcenter

New-EC2Tag  -Resource $ec2_id -Tag $tag
New-EC2Tag  -Resource $ec2_id -Tag $tag2
New-EC2Tag  -Resource $ec2_id -Tag $tag3
#>

  #Get the EC2 Instance-ID
  $instanceId = Invoke-WebRequest -Uri http://169.254.169.254/latest/meta-data/instance-id -UseBasicParsing
  $ec2_id = $instanceid.Content

  #Get the EC2 Tag value for "Name". Used to set the machine Hostname with.
  $hostname = (((Get-EC2Instance -InstanceId $ec2_id).Instances).Tags | Where-Object -Property Key -EQ "Name" | Select-Object -ExpandProperty Value)




  #Add EC2 Name Tag to all EBS Volumes.
  (Get-EC2Instance -InstanceId $ec2_id).Instances | # Get Current EC2 instance and pass to pipeline
  ForEach-Object -Process {
    # Get the name tag of the current instance ID; Amazon.EC2.Model.Tag is in the Instances object
    $instanceName = $_.Tags | Where-Object -Property Key -EQ "Name" | Select-Object -ExpandProperty Value
    $_.BlockDeviceMappings | # Pass all the current block device objects down the pipeline
    ForEach-Object -Process {
      $volumeid = $_.ebs.volumeid # Retrieve current volume id for this BDM in the current instance
      # Get the current volume's Name tag
      $volumeNameTag = Get-EC2Tag -Filter @(@{ name = 'tag:Name'; values = "*" }; @{ name = "resource-type"; values = "volume" }; @{ name = "resource-id"; values = $volumeid }) | Select-Object -ExpandProperty Value
        
      if (-not $volumeNameTag) { # Replace the tag in the volume if it is blank
        New-EC2Tag -Resources $volumeid -Tags @{ Key = "Name"; Value = $instanceName } # Add volume name tag that matches InstanceID
        #Not needed this tag set at Terraform
        #New-EC2Tag -Resources $volumeid -Tags @{ Key = "cost-center"; Value = $costcenter }
      }
    }
  }



  # Create a new Schedule Task to launch the on_reboot_once.ps1 Powershell script when server reboots. Make sure Working Directory is entered, as some scripts may need it to launch items found in it.
  $action = New-ScheduledTaskAction -Execute 'Powershell.exe' ` -Argument '-ExecutionPolicy Bypass D:\Scripts\on_reboot_once.ps1' -WorkingDirectory 'd:\scripts\'
  $trigger = New-ScheduledTaskTrigger -AtStartup
  $User = "SYSTEM"
  Register-ScheduledTask -Action $action -Trigger $trigger -User $User -RunLevel "Highest" -TaskName "Finish_Setup_On_Reboot" -Description "Run once on initial reboot to finish server setup"


  # Create the Credential Object to be used in Renaming the server.
  $User = "mrirdp\limited_acct_test"
  $PWord = ConvertTo-SecureString -String "Wife35%Dry" -AsPlainText -Force
  $Credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $User, $PWord

  #Setting a parameter for date/time the script runs and pass to a file out.
  $a = Get-Date
  $run_time = "Script ran on: " + $a.ToUniversalTime() + " UTC"
  # Creates a file and drops in Date/Time the script ran.
  Write-Output "Start up script initiated on: "$run_time | Out-File C:\Start_Up_Script_runlog.txt -Append
}

Catch {
  #If any errors come from script above, it will write them to this file.
  $_ | Out-File C:\Start_Up_Script_errorlog.txt -Append
}

Try {
  #Rename the server, Join the Domain and restart server so new name takes effect. On reboot the Scheduled Task will run a ps1 file to complete the setup.


  Rename-Computer -NewName $HostName -Force
  sleep 5
  Add-Computer -DomainName "MRIRDP.com" -Credential $Credential -Options JoinWithNewName, AccountCreate -force #-restart

  #Restart Computer
  Restart-Computer -Force

}

Catch {
  #If any errors come from renaming the server, it will write them to this file.
  $_ | Out-File C:\Start_Up_Script_errorlog.txt -Append
}
###
### STEP 1: Register the script to run at startup (this needs to be done only once as ADMIN)
### $trigger = New-JobTrigger -AtStartup -RandomDelay 00:00:30
###  -FilePath C:\temp\MfilesContentPackageGitUploader.ps1 -Name MfilesContentPackageGitUploader

### STEP 2: Create the MfilesContentPackageGitUploader.ps1:

$folder = "C:\M-Files Content Packages\Project-K Acceptance\Out\Full structure"

# Register the file listener.
$filter = "Ready" # The file 'Ready' means that the content package is ready.                             
$fsw = New-Object IO.FileSystemWatcher $folder, $filter 
$fsw.IncludeSubdirectories = $true              
Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated -Action {      
    
    # Move and rename folder contents. 
    $source = Split-Path -Path $Event.SourceEventArgs.FullPath     
    $destination = "C:\temp\vault-structure-project-k"
    
    # Remove non-git files from the folder if it exists.
    If ( $(Test-Path $destination -IsValid) -eq $True ) {
     
        $Exclusions = ".git"

        Get-ChildItem -Path $destination -Recurse -Exclude $Exclusions | 
            Select -ExpandProperty FullName | 
            Sort Length -Descending | 
            Remove-Item -Recurse -Force

    }
    
    # Move the folder contents and delete the original.
    Move-Item -Path $($source + "\*") -destination $destination -Force 
    Remove-Item $source -Force -Recurse 

   
    # Create custom Script block to execute Git:
    $invokeGit= {
        Param (
            [Parameter(
                Mandatory=$true
            )]
            [string]$Reason,
            [Parameter(
                Mandatory=$true
            )]
            [string[]]$ArgumentsList
        )
        try
        {
            $gitPath=& "C:\Windows\System32\where.exe" git
            $gitErrorPath=Join-Path $env:TEMP "stderr.txt"
            $gitOutputPath=Join-Path $env:TEMP "stdout.txt"
            if($gitPath.Count -gt 1)
            {
                $gitPath=$gitPath[0]
            }

            Write-Verbose "[Git][$Reason] Begin"
            Write-Verbose "[Git][$Reason] gitPath=$gitPath"
            Write-Host "git $arguments"
            $process=Start-Process $gitPath -ArgumentList $ArgumentsList -NoNewWindow -PassThru -Wait -RedirectStandardError $gitErrorPath -RedirectStandardOutput $gitOutputPath
            $outputText=(Get-Content $gitOutputPath)
            $outputText | ForEach-Object {Write-Host $_}

            Write-Verbose "[Git][$Reason] process.ExitCode=$($process.ExitCode)"
            if($process.ExitCode -ne 0)
            {
                Write-Warning "[Git][$Reason] process.ExitCode=$($process.ExitCode)"
                $errorText=$(Get-Content $gitErrorPath)
                $errorText | ForEach-Object {Write-Host $_}

                if($errorText -ne $null)
                {
                    exit $process.ExitCode
                }
            }
            return $outputText
        }
        catch
        {
            Write-Error "[Git][$Reason] Exception $_"
        }
        finally
        {
            Write-Verbose "[Git][$Reason] Done"
        }
    }
    

    # Finally add, commit and push to origin.
    
    cd $destination

    $arguments=@(
        "add"
        "."
    )
    $status=Invoke-Command -ScriptBlock $invokeGit -ArgumentList "Add all",$arguments

    $arguments=@(
        "commit"
        "-m"
        """autoupdated on $(date)"""
    )
    $status=Invoke-Command -ScriptBlock $invokeGit -ArgumentList "Commit",$arguments

    $arguments=@(
        "push"
        "origin"
        "master"
    )
    $status=Invoke-Command -ScriptBlock $invokeGit -ArgumentList "Push",$arguments

 } 

### STEP 3: Unregister the event and job when you no longer need it.
### Unregister-Event -SourceIdentifier FileCreated
### Unregister-ScheduledJob MfilesContentPackageGitUploader



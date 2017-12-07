
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
    $destination = "C:\temp\proj-k-struct"
    
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

 } 

### STEP 3: Unregister the event and job when you no longer need it.
### Unregister-Event -SourceIdentifier FileCreated
### Unregister-ScheduledJob MfilesContentPackageGitUploader

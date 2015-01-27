# VSIX Module for AppVeyor by Mads Kristensen

$vsixUploadEndpoint = "http://vsixgallery.com/extension/uploadFile"
#$vsixUploadEndpoint = "http://localhost:7035/extension/uploadFile"

function Vsix-PushArtifacts {

    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=0)]
        [string]$path = "**/bin/*/*.vsix",

        [switch]$publishToGallery
    ) 

    $fileName = Get-ChildItem $path

    Write-Host ("Pushing artifact " + $fileName.Name + "...") -ForegroundColor Cyan -NoNewline
    Push-AppveyorArtifact $fileName.FullName -FileName $fileName.Name
    Write-Host "OK" -ForegroundColor Green

    if ($publishToGallery){
        vsix-PublishToGallery $fileName.FullName
    }
}

function vsix-PublishToGallery{

    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=0)]
        [string]$path = "**/bin/*/*.vsix"
    ) 

    if ($env:APPVEYOR_PULL_REQUEST_NUMBER){
        return
    }

    $repo = ""
    $issueTracker = ""

    if ($env:APPVEYOR_REPO_PROVIDER -contains "github"){
        [Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
        $repo = [System.Web.HttpUtility]::UrlEncode(("https://github.com/" + $env:APPVEYOR_REPO_NAME + "/"))
        $issueTracker = [System.Web.HttpUtility]::UrlEncode(($repo + "issues/"))
    }

    Write-Host "Publish to VSIX Gallery..." -ForegroundColor Cyan -NoNewline

    $fileName = (Get-ChildItem $path)[0]

    [string]$url = ($vsixUploadEndpoint + "?repo=" + $repo + "&issuetracker=" + $issueTracker)
    [byte[]]$bytes = Get-Content $fileName -Encoding byte
    
    try {
        $response = Invoke-WebRequest $url -Method Post -Body $bytes
        Write-Host "OK" -ForegroundColor Green
    } catch{
        Write-Host "FAIL" -ForegroundColor Red
        write-host $_.Exception.Response.Headers["x-error"]
    }    
}

function Vsix-UpdateBuildVersion {

    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=1)]
        [Version]$version
    ) 

    Write-Host "Updating AppVeyor build version..." -ForegroundColor Cyan -NoNewline
    Update-AppveyorBuild -Version $version
    Write-Host $version -ForegroundColor Green
}

function Vsix-IncrementVsixVersion {

    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=0)]
        [string]$manifestFilePath = "**\source.extension.vsixmanifest",

        [Parameter(Position=1, Mandatory=0)]
        [int]$buildNumber = $env:APPVEYOR_BUILD_NUMBER,

        [ValidateSet("build","revision")]
        [Parameter(Position=2, Mandatory=0)]
        [string]$versionType = "build",

        [switch]$updateBuildVersion
    )

    Write-Host "`nIncrementing VSIX version..."  -ForegroundColor Cyan -NoNewline

    $vsixManifest = Get-ChildItem $manifestFilePath
    [xml]$vsixXml = Get-Content $vsixManifest

    $ns = New-Object System.Xml.XmlNamespaceManager $vsixXml.NameTable
    $ns.AddNamespace("ns", $vsixXml.DocumentElement.NamespaceURI)

    $attrVersion = $vsixXml.SelectSingleNode("//ns:Identity", $ns).Attributes["Version"]

    [Version]$version = $attrVersion.Value;

    if ($versionType -eq "build"){
        $version = New-Object Version ([int]$version.Major),([int]$version.Minor),$buildNumber
    }
    elseif ($versionType -eq "revision"){
        $version = New-Object Version ([int]$version.Major),([int]$version.Minor),([System.Math]::Max([int]$version.Build, 0)),$buildNumber
    }
        
    $attrVersion.Value = $version
    $vsixXml.Save($vsixManifest)

    Write-Host $version.ToString() -ForegroundColor Green

    if ($updateBuildVersion -and $env:APPVEYOR_BUILD_VERSION -ne $version.ToString()){
        Vsix-UpdateBuildVersion $version
    }
}

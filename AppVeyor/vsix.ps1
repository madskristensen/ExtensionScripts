# VSIX Module for AppVeyor by Mads Kristensen

function Vsix-Build {

    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=0)]
        [string]$file = "*.sln",

        [Parameter(Position=1, Mandatory=0)]
        [string]$configuration = "Release",

        
        [switch]$updateBuildVersion,
        [switch]$pushArtifacts
    ) 

    $buildFile = Get-ChildItem $file
    $env:CONFIGURATION = $configuration

    Write-Host "Building" $buildFile.Name -ForegroundColor cyan
    msbuild $buildFile.FullName /p:configuration=$configuration /p:DeployExtension=false /p:ZipPackageCompressionLevel=normal /v:m

    if ($updateBuildVersion){
        Vsix-UpdateBuildVersion
    }

    if ($pushArtifacts){
        Vsix-PushArtifacts -configuration $configuration
    }
}

function Vsix-PushArtifacts {

    [CmdletBinding()]
    param (
        [Parameter(Position=1, Mandatory=0)]
        [string]$configuration = $env:CONFIGURATION,
        
        [Parameter(Position=0, Mandatory=0)]
        [string]$path = "**/bin/$configuration/*.vsix"
    ) 

    $fileName = Get-ChildItem $path

    Write-Host "Pushing artifact" $fileName.Name"..." -ForegroundColor Cyan -NoNewline
    Push-AppveyorArtifact $fileName.FullName -FileName $fileName.Name
    Write-Host "OK" -ForegroundColor Green
}

function Vsix-UpdateBuildVersion {

    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=0)]
        [Version]$version = $env:APPVEYOR_BUILD_VERSION
    ) 

    Write-Host "Updating AppVeyor build version..." -ForegroundColor Cyan -NoNewline
    Update-AppveyorBuild -Version $version
    Write-Host $version -ForegroundColor Green
}

function Vsix-IncrementVersion {

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

    $env:APPVEYOR_BUILD_VERSION = $version.ToString()

    Write-Host $version.ToString() -ForegroundColor Green

    if ($updateBuildVersion){
        Vsix-UpdateBuildVersion $version
    }
}

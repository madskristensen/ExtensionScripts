# VSIX Module for AppVeyor by Mads Kristensen


function Vsix-Build{

    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=0)]
        [string]$file = "*.sln",

        [Parameter(Position=1, Mandatory=0)]
        [string]$configuration = "Release"
    ) 

    $buildFile = Get-ChildItem $file

    msbuild $buildFile.FullName /p:configuration=$configuration /p:DeployExtension=false /p:ZipPackageCompressionLevel=normal /v:m
}

function Vsix-IncrementVersion{

    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=0)]
        [string]$manifestFilePath = "**\source.extension.vsixmanifest",

        [Parameter(Position=1, Mandatory=0)]
        [int]$buildNumber = $env:APPVEYOR_BUILD_NUMBER,

        [ValidateSet("build","revision")]
        [Parameter(Position=2, Mandatory=0)]
        [string]$versionSpot = "build"
    )

    Write-Host "`nIncrementing VSIX version... "  -ForegroundColor Cyan -NoNewline

    $vsixManifest = Get-ChildItem $manifestFilePath
    [xml]$vsixXml = Get-Content $vsixManifest

    $ns = New-Object System.Xml.XmlNamespaceManager $vsixXml.NameTable
    $ns.AddNamespace("ns", $vsixXml.DocumentElement.NamespaceURI)

    $attrVersion = $vsixXml.SelectSingleNode("//ns:Identity", $ns).Attributes["Version"]

    [Version]$version = $attrVersion.Value;

    if ($versionSpot -eq "build"){
        $version = New-Object Version ([int]$version.Major),([int]$version.Minor),$buildNumber
    }
    elseif ($versionSpot -eq "revision"){
        $version = New-Object Version ([int]$version.Major),([int]$version.Minor),([System.Math]::Max([int]$version.Build, 0)),$buildNumber
    }
        
    [Version]$newVersion = $Version
    $attrVersion.Value = $newVersion

    $vsixXml.Save($vsixManifest)

    Write-Host "" $newVersion.ToString() `n -ForegroundColor Green

    # Updating the AppVeyor build version
    Write-Host "Updating AppVeyor build..." -ForegroundColor Cyan -NoNewline
    Update-AppveyorBuild -Version = $newVersion.ToString()
    Write-Host "OK" -ForegroundColor Green
}
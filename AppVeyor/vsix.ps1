# VSIX Module for AppVeyor by Mads Kristensen

function Vsix-IncrementVersion{

    [CmdletBinding()]
    param (
        [Parameter(Position=0, Mandatory=0)]
        [string]$manifestFilePath = "**\source.extension.vsixmanifest",

        [Parameter(Position=1, Mandatory=0)]
        [int]$buildNumber = $env:APPVEYOR_BUILD_NUMBER
    )

    Write-Host "`nIncrementing VSIX version... "  -ForegroundColor Cyan -NoNewline

    $vsixManifest = Get-ChildItem $manifestFilePath
    [xml]$vsixXml = Get-Content $vsixManifest

    $ns = New-Object System.Xml.XmlNamespaceManager $vsixXml.NameTable
    $ns.AddNamespace("ns", $vsixXml.DocumentElement.NamespaceURI)

    $version = $vsixXml.SelectSingleNode("//ns:Identity", $ns).Attributes["Version"]
    
    [Version]$newVersion = $version.Value + "." + $buildNumber
    $version.Value = $newVersion

    $vsixXml.Save($vsixManifest)

    Write-Host $newVersion.ToString() `n -ForegroundColor Green
}
[CmdletBinding()]
Param(
    [switch]$incrementVersion
)


# Variables
$vsixManifest     = Resolve-Path "**\source.extension.vsixmanifest"
[int]$buildNumber = $env:APPVEYOR_BUILD_NUMBER


# Increment VSIX version
if ($incrementVersion){

    echo "Incrementing VSIX version"

    [xml]$vsixXml = Get-Content $vsixManifest

    $ns = New-Object System.Xml.XmlNamespaceManager $vsixXml.NameTable
    $ns.AddNamespace("ns", $vsixXml.DocumentElement.NamespaceURI)

    $version = $vsixXml.SelectSingleNode("//ns:Identity", $ns).Attributes["Version"]
    
    [Version]$newVersion = $version.Value + "." + $buildNumber
    $version.Value = $newVersion

    $vsixXml.Save($vsixManifest)

    echo ("VSIX version " + $newVersion.ToString())
}
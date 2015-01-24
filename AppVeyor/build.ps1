$vsixFilePathToUpdate = Resolve-Path "*\source.extension.vsixmanifest"
[xml]$vsixXml = (Get-Content $vsixFilePathToUpdate)
$ns = New-Object System.Xml.XmlNamespaceManager $vsixXml.NameTable
$ns.AddNamespace("ns", $vsixXml.DocumentElement.NamespaceURI)
$vsixXml.SelectSingleNode("//ns:Identity", $ns).Attributes["Version"].Value += "." + $env:APPVEYOR_BUILD_NUMBER
$vsixXml.Save($vsixFilePathToUpdate);
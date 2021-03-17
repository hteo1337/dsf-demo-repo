[CmdletBinding()]

param(
    [Parameter()]
    [string] $licenseCode
)

#Enable TLS12
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

function Main() {
    $siteName = 'UiPathProcessMining'
    $dnsName = $env:computername 

    # create the ssl certificate
    $newCert = New-SelfSignedCertificate  -DnsName $dnsName -CertStoreLocation cert:\LocalMachine\My

    # get the web binding of the site
    $binding = Get-WebBinding -Name $siteName -Protocol "https"

    # set the ssl certificate
    $binding.AddSslCertificate($newCert.GetCertHashString(), "my")


    Start-Process "iisreset.exe" -NoNewWindow 

    # confige bindings for http/https
    New-WebBinding -Name 'UiPathProcessMining' -Protocol http -Port 80
    Remove-WebBinding -Name 'UiPathProcessMining' -BindingInformation '*:443:'

    if ($licenseCode) {
        licensePM -license $licenseCode
    }
}
function licensePM() {
    param(
        [Parameter()]
        [string] $license
    )

    Start-Process -FilePath 'C:\Windows\System32\cmd.exe' -ArgumentList '/c', 'C:\UiPathProcessMining\builds\magnaview.bat', "  -license -activate $license"
}

Main

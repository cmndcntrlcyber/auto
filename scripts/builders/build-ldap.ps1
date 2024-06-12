# Generate a self-signed certificate
$cert = New-SelfSignedCertificate -DnsName "dc.domain.root" -CertStoreLocation "Cert:\LocalMachine\My" -KeySpec KeyExchange

# Export the certificate to a file
$certPath = "C:\ldaps-cert.cer"
Export-Certificate -Cert $cert -FilePath $certPath

# Import the certificate into the Trusted Root Certification Authorities
Import-Certificate -FilePath $certPath -CertStoreLocation "Cert:\LocalMachine\Root"

# Restart the domain controller to apply the certificate
Restart-Computer

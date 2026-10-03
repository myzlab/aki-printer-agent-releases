<#
.SYNOPSIS
    Instala en la PC del cliente el certificado público con el que se firma el agente.

.DESCRIPTION
    Se ejecuta una vez por PC, antes de instalar el agente. Pide permisos de administrador.
    Agrega AkiPrinterAgent.cer a "Entidades de certificación raíz de confianza" y a "Editores de confianza"
    del equipo, para que Windows reconozca como válida la firma de "Akí Mismo" en el instalador y en el agente.

    Copia junto a este script el archivo AkiPrinterAgent.cer (está en certs\ del repo).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install-certificate.ps1
#>
[CmdletBinding()]
param(
    [string] $CertPath
)

$ErrorActionPreference = 'Stop'

if (-not $CertPath) {
    $candidates = @(
        (Join-Path $PSScriptRoot 'AkiPrinterAgent.cer'),
        (Join-Path (Split-Path -Parent $PSScriptRoot) 'certs\AkiPrinterAgent.cer')
    )
    $CertPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $CertPath) {
        throw 'No se encontró AkiPrinterAgent.cer. Cópialo junto a este script o indica la ruta con -CertPath.'
    }
}

$CertPath = (Resolve-Path $CertPath).Path

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -Verb RunAs -Wait -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', "`"$PSCommandPath`"",
        '-CertPath', "`"$CertPath`""
    )
    return
}

Import-Certificate -FilePath $CertPath -CertStoreLocation 'Cert:\LocalMachine\Root' | Out-Null
Import-Certificate -FilePath $CertPath -CertStoreLocation 'Cert:\LocalMachine\TrustedPublisher' | Out-Null

Write-Host 'Certificado de Akí Mismo instalado. Ya puedes ejecutar el instalador del agente.' -ForegroundColor Green
Read-Host 'Presiona Enter para cerrar'

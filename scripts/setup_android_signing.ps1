$ErrorActionPreference = 'Stop'

$appRoot = Split-Path -Parent $PSScriptRoot
$propertiesPath = Join-Path $appRoot 'android\key.properties'
$signingDirectory = Join-Path $env:USERPROFILE '.proxvel-signing'
$keystorePath = Join-Path $signingDirectory 'proxvel-release.jks'

if ((Test-Path -LiteralPath $keystorePath) -or (Test-Path -LiteralPath $propertiesPath)) {
    throw 'Ya existe la llave o key.properties. No se reemplazará una identidad de firma existente.'
}

$keytool = Get-Command keytool.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1
if (-not $keytool) {
    $javaDirectory = Join-Path $env:LOCALAPPDATA 'Java'
    $keytool = Get-ChildItem -LiteralPath $javaDirectory -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName 'bin\keytool.exe' } |
        Where-Object { Test-Path -LiteralPath $_ } |
        Select-Object -First 1
}
if (-not $keytool) { throw 'No se encontró keytool.exe. Instala JDK 17 o agrega keytool al PATH.' }

New-Item -ItemType Directory -Path $signingDirectory -Force | Out-Null
Write-Host 'Crea en tu gestor una contraseña aleatoria de al menos 20 caracteres alfanuméricos.'
$securePassword = Read-Host 'Escribe esa contraseña para configurar Gradle' -AsSecureString
$plainPassword = [System.Net.NetworkCredential]::new('', $securePassword).Password
if ($plainPassword -notmatch '^[A-Za-z0-9]{20,}$') {
    throw 'Usa al menos 20 caracteres alfanuméricos.'
}
Write-Host 'keytool pedirá la misma contraseña y datos del certificado. Usa la misma clave para la llave y el almacén.'
& $keytool -genkeypair -v -storetype PKCS12 -keystore $keystorePath -keyalg RSA -keysize 3072 -validity 10000 -alias proxvel-release
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $keystorePath)) {
    throw 'keytool no creó la llave. No se generó key.properties.'
}

$securePassword = Read-Host 'Escribe la contraseña que keytool aceptó (puede ser distinta del primer intento)' -AsSecureString
$plainPassword = [System.Net.NetworkCredential]::new('', $securePassword).Password
$forwardPath = $keystorePath.Replace('\', '/')
@(
    "storeFile=$forwardPath"
    "storePassword=$plainPassword"
    'keyAlias=proxvel-release'
    "keyPassword=$plainPassword"
) | Set-Content -LiteralPath $propertiesPath -Encoding ascii
Remove-Variable plainPassword, securePassword
Write-Host "Firma configurada. Llave: $keystorePath"
Write-Host 'Haz una copia de seguridad de la llave y guarda la contraseña en tu gestor. No subas estos archivos a Git.'

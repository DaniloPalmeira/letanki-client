# Gera build\LeTanki.exe com o adt do AIR SDK 32.
#
#   powershell -File package.ps1            # so gera, em build\
#   powershell -File package.ps1 -Install   # gera e troca o exe do payload
#
# O launcher do AIR nao tem codigo nosso: e o CaptiveAppEntry.exe do SDK com os
# icones injetados na secao .rsrc. Por isso a "fonte" dele e o descritor mais os
# icones que ja estao em app\, e nao src\. Conferido secao a secao: .text,
# .rdata, .data e .reloc do exe gerado sao identicos aos do template do SDK.
#
# ATENCAO -- o exe que sai daqui NAO e byte a byte o app\LeTanki.exe versionado.
# O payload original foi empacotado com AIR 22.0.0.153 e este SDK e o AIR
# 32.0.0.116; os templates sao binarios diferentes (69.432 vs 82.944 bytes).
# Testado: o stub do 32 sobe normal sobre o runtime captive 22 de app\Adobe AIR.
# Ainda assim -Install muda o que vai instalado no PC do usuario -- e decisao,
# nao detalhe de build. Fora isso, o adt embaralha os IDs dos icones no .rsrc a
# cada rodada, entao duas execucoes seguidas ja dao arquivos diferentes.
param([switch]$Install)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

Push-Location $root
try {
    # Mesma ordem de busca do build.ps1: $env:FLEX_SDK, depois tools\flex-sdk.
    $sdk = $env:FLEX_SDK
    if (-not $sdk) { $sdk = 'tools\flex-sdk' }
    if (-not (Test-Path "$sdk\bin\adt.bat")) {
        throw "SDK do Flex nao encontrado em '$sdk'. Aponte `$env:FLEX_SDK ou crie tools\flex-sdk (ver README)."
    }

    New-Item -ItemType Directory -Force 'build' | Out-Null
    $bundle = 'build\bundle'
    $cert = 'build\adt-cert.p12'
    if (Test-Path $bundle) { Remove-Item -Recurse -Force $bundle }

    # O adt exige assinatura mesmo em -target bundle, mas ela so aparece no
    # META-INF do bundle, que a gente descarta. Certificado auto assinado,
    # descartavel, refeito a cada rodada -- nao ha nada para guardar aqui.
    & "$sdk\bin\adt.bat" -certificate -cn LeTanki 2048-RSA $cert letanki
    if ($LASTEXITCODE -ne 0) { throw "adt -certificate falhou (exit $LASTEXITCODE)" }

    # -tsa none: o timestamp server padrao do adt morreu junto com a Adobe; sem
    # isso ele para em "Could not generate timestamp: Connection reset".
    # O fileset e so icons + SWF porque o descritor referencia os dois e o adt
    # recusa empacotar sem eles; do fileset, so os icones entram no exe.
    & "$sdk\bin\adt.bat" -package `
        -storetype pkcs12 -keystore $cert -storepass letanki -tsa none `
        -target bundle $bundle `
        'app\META-INF\AIR\application.xml' `
        -C 'app' 'icons' 'StandaloneLoader-2.0.swf'
    if ($LASTEXITCODE -ne 0) { throw "adt -package falhou (exit $LASTEXITCODE)" }

    Copy-Item "$bundle\LeTanki.exe" 'build\LeTanki.exe' -Force

    # O resto do bundle e runtime AIR 32 (27 MB) e um META-INF assinado por nos.
    # Nada disso vai para app\, entao nao fica para tras se passando por payload.
    Remove-Item -Recurse -Force $bundle, $cert

    Write-Host "build\LeTanki.exe  ($((Get-Item 'build\LeTanki.exe').Length) bytes)"

    if ($Install) {
        Copy-Item 'build\LeTanki.exe' 'app\LeTanki.exe' -Force
        Write-Host 'instalado em app\LeTanki.exe'
    } else {
        Write-Host 'use -Install para trocar o exe em app\'
    }
} finally { Pop-Location }

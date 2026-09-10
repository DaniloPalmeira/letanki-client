# Compila src/ -> build/StandaloneLoader-2.0.swf.
#
#   powershell -File build.ps1            # so compila, em build/
#   powershell -File build.ps1 -Install   # compila e troca o SWF do payload
#
# O -Install e separado de proposito: compilar "so para checar" nao pode
# sujar app/, que e a imagem do que vai instalado no PC do usuario.
param([switch]$Install)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

# O parser de linha de comando do mxmlc quebra em caminho absoluto com espaco,
# entao tudo aqui roda relativo a raiz do repositorio.
Push-Location $root
try {
    # Onde esta o Apache Flex 4.16.1 + overlay do AIR SDK 32. Ordem:
    # $env:FLEX_SDK, depois tools\flex-sdk (junction ou copia local).
    $sdk = $env:FLEX_SDK
    if (-not $sdk) { $sdk = 'tools\flex-sdk' }
    if (-not (Test-Path "$sdk\bin\mxmlc.bat")) {
        throw "SDK do Flex nao encontrado em '$sdk'. Aponte `$env:FLEX_SDK ou crie tools\flex-sdk (ver README)."
    }

    New-Item -ItemType Directory -Force 'build' | Out-Null
    $swf = 'build\StandaloneLoader-2.0.swf'

    # +configname=air: o loader usa flash.desktop.NativeApplication e
    # flash.display.Screen, que so existem no perfil AIR.
    # -swf-version=17 = Flash Player 11.4, a versao do SWF original. O runtime
    # embarcado no instalador e o AIR 22, que recusa SWF mais novo -- nao
    # aumentar sem testar no LeTanki.exe de verdade.
    & "$sdk\bin\mxmlc.bat" `
        '+configname=air' `
        '-static-link-runtime-shared-libraries=true' `
        '-swf-version=17' '-debug=false' `
        '-source-path' 'src' `
        '-output' $swf `
        'src\projects\tanks\clients\fp10\StandaloneLoader\StandaloneLoader.as'
    if ($LASTEXITCODE -ne 0) { throw "mxmlc falhou (exit $LASTEXITCODE)" }

    Write-Host "$swf  ($((Get-Item $swf).Length) bytes)"

    if ($Install) {
        Copy-Item $swf 'app\StandaloneLoader-2.0.swf' -Force
        Write-Host 'instalado em app\StandaloneLoader-2.0.swf'
    } else {
        Write-Host 'use -Install para trocar o SWF em app\'
    }
} finally { Pop-Location }

# Monta build\ -- o cliente completo e rodavel.
#
#   powershell -File package.ps1
#
# Entradas:
#   application.xml   descritor: enderecos do CDN e parametros do loader
#   icons\            icones do launcher
#   src\              fonte do SWF; o build.ps1 compila em obj\, chamado aqui
#   deps\Adobe AIR\   runtime captive AIR 22.0.0.153 -- a unica dependencia
#                     binaria, e a unica coisa do cliente que nao se gera
#
# O adt monta o exe, o META-INF e o mimetype. O runtime que ele embarca e o do
# proprio SDK (AIR 32) e e trocado pelo de deps\, que e a versao com que este
# cliente sempre rodou -- e a que o -swf-version=17 do build.ps1 respeita.
#
# O launcher nao tem codigo nosso: e o CaptiveAppEntry.exe do SDK com os icones
# injetados na secao .rsrc. Conferido secao a secao, .text, .rdata, .data e
# .reloc do exe gerado sao identicos aos do template do SDK. Ele tambem nao sai
# igual entre rodadas: o adt distribui os IDs dos icones em ordem arbitraria.
#
# O certificado e auto assinado e nao vale nada -- o original era da Alternativa
# Game Ltd e nao ha como reproduzir sem a chave privada dela. Fica fixo em
# adt-cert.p12 (fora do git) so para o META-INF nao mudar a cada rodada.
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

    & "$root\build.ps1"

    $cert = 'adt-cert.p12'
    $dest = 'build'

    # O adt exige assinatura mesmo em -target bundle. Gera o certificado uma vez
    # e reaproveita: assim o META-INF sai igual em toda rodada.
    if (-not (Test-Path $cert)) {
        & "$sdk\bin\adt.bat" -certificate -cn LeTanki 2048-RSA $cert letanki
        if ($LASTEXITCODE -ne 0) { throw "adt -certificate falhou (exit $LASTEXITCODE)" }
        Write-Host "certificado novo em $cert"
    }

    # Com o cliente aberto, o Adobe AIR.dll fica travado e o Remove-Item abaixo
    # falha com "acesso negado", que nao diz nada sobre a causa real.
    if (Get-Process -Name LeTanki -ErrorAction SilentlyContinue) {
        throw 'LeTanki esta aberto. Feche antes: o build\ nao pode ser trocado com o runtime carregado.'
    }
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }

    # -tsa none: o timestamp server padrao do adt morreu junto com a Adobe; sem
    # isso ele para em "Could not generate timestamp: Connection reset".
    & "$sdk\bin\adt.bat" -package `
        -storetype pkcs12 -keystore $cert -storepass letanki -tsa none `
        -target bundle $dest 'application.xml' `
        -C '.' 'icons' `
        -C 'obj' 'StandaloneLoader-2.0.swf'
    if ($LASTEXITCODE -ne 0) { throw "adt -package falhou (exit $LASTEXITCODE)" }

    # Fora o runtime, que vem de deps\ e nao do SDK.
    Remove-Item -Recurse -Force "$dest\Adobe AIR"
    Copy-Item -Recurse 'deps\Adobe AIR' "$dest\Adobe AIR"

    Write-Host "$dest\  -- cliente pronto, rode $dest\LeTanki.exe"
} finally { Pop-Location }

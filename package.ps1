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
#
#   powershell -File package.ps1 -Xp
#
# Monta a variante para Windows XP em build-xp\ e dist\LeTanki-xp.zip. O
# SChannel do XP nao fala TLS 1.2 nem manda SNI, entao o HTTPS do Cloudflare
# nunca fecha o handshake: essa variante troca todo https:// do descritor por
# http://, o que exige o res.letanki.com aceitar HTTP sem redirecionar. Sai em
# zip porque o Inno Setup 6 nao roda no XP.
param([switch]$Xp)
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
    $descriptor = 'application.xml'
    if ($Xp) {
        $dest = 'build-xp'
        $descriptor = 'obj\application-xp.xml'
        $xml = [IO.File]::ReadAllText("$root\application.xml") -replace 'https://', 'http://'
        [IO.File]::WriteAllText("$root\$descriptor", $xml)
    }

    # O adt exige assinatura mesmo em -target bundle. Gera o certificado uma vez
    # e reaproveita: assim o META-INF sai igual em toda rodada.
    if (-not (Test-Path $cert)) {
        & "$sdk\bin\adt.bat" -certificate -cn LeTanki 2048-RSA $cert letanki
        if ($LASTEXITCODE -ne 0) { throw "adt -certificate falhou (exit $LASTEXITCODE)" }
        Write-Host "certificado novo em $cert"
    }

    # Com o cliente aberto, o Adobe AIR.dll fica travado e o Remove-Item abaixo
    # falha com "acesso negado", que nao diz nada sobre a causa real.
    $full = [IO.Path]::GetFullPath("$root\$dest")
    if (Get-Process -Name LeTanki -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$full\*" }) {
        throw "LeTanki esta aberto. Feche antes: o build\ nao pode ser trocado com o runtime carregado."
    }
    if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }

    # -tsa none: o timestamp server padrao do adt morreu junto com a Adobe; sem
    # isso ele para em "Could not generate timestamp: Connection reset".
    & "$sdk\bin\adt.bat" -package `
        -storetype pkcs12 -keystore $cert -storepass letanki -tsa none `
        -target bundle $dest $descriptor `
        -C '.' 'icons' `
        -C 'obj' 'StandaloneLoader-2.0.swf'
    if ($LASTEXITCODE -ne 0) { throw "adt -package falhou (exit $LASTEXITCODE)" }

    # Fora o runtime, que vem de deps\ e nao do SDK.
    Remove-Item -Recurse -Force "$dest\Adobe AIR"
    Copy-Item -Recurse 'deps\Adobe AIR' "$dest\Adobe AIR"

    # Liga o bit IMAGE_FILE_LARGE_ADDRESS_AWARE no cabecalho PE do exe. O
    # launcher e de 32 bits e sem o bit o processo tem 2 GB de espaco de
    # endereco; medido em 2026-10-02 no cliente instalado: uma sessao normal
    # sobe de 1,6 para 2,0 GB virtuais ao longo de algumas batalhas e, ao bater
    # no teto, o runtime falha a alocacao, derruba as threads e o cliente
    # congela ("parou de responder") -- antes disso texturas comecam a falhar
    # ao subir para a GPU (Error #3691) e somem ou piscam. Com o bit, o Windows
    # de 64 bits da 4 GB ao processo. Em Windows de 32 bits (e XP) o bit e
    # ignorado e nada muda. O runtime e o mesmo que o adl.exe com este bit
    # roda em depuracao desde 2026-09-25 (tools\adl-laa no repositorio do
    # cliente), sem efeito colateral. O exe nao e assinado, entao mexer no
    # cabecalho nao invalida nada; quando a assinatura entrar, este passo tem
    # de vir antes dela.
    $exe = Join-Path $full 'LeTanki.exe'
    $bytes = [IO.File]::ReadAllBytes($exe)
    $pe = [BitConverter]::ToInt32($bytes, 0x3C)
    if ($bytes[$pe] -ne 0x50 -or $bytes[$pe + 1] -ne 0x45) { throw "LeTanki.exe nao tem cabecalho PE em $pe" }
    $flags = [BitConverter]::ToUInt16($bytes, $pe + 22)
    if (($flags -band 0x20) -eq 0) {
        $flags = [uint16]($flags -bor 0x20)
        [Array]::Copy([BitConverter]::GetBytes($flags), 0, $bytes, $pe + 22, 2)
        [IO.File]::WriteAllBytes($exe, $bytes)
    }
    $check = [BitConverter]::ToUInt16([IO.File]::ReadAllBytes($exe), $pe + 22)
    if (($check -band 0x20) -eq 0) { throw 'nao consegui ligar o bit LAA em LeTanki.exe' }
    Write-Host ('LeTanki.exe: LARGE_ADDRESS_AWARE ligado (Characteristics 0x{0:x})' -f $check)

    if ($Xp) {
        New-Item -ItemType Directory -Force 'dist' | Out-Null
        Compress-Archive -Force "$dest\*" 'dist\LeTanki-xp.zip'
        Write-Host 'dist\LeTanki-xp.zip  -- variante XP, descompactar e rodar LeTanki.exe'
    }
    Write-Host "$dest\  -- cliente pronto, rode $dest\LeTanki.exe"
} finally { Pop-Location }

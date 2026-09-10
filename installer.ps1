# Gera dist\LeTanki-setup.exe.
#
#   powershell -File installer.ps1
#
# Roda o package.ps1 antes, para o instalador nunca empacotar um build velho.
# Precisa do Inno Setup 6 -- o mesmo empacotador do instalador original do
# LeTanki. Procura em $env:INNO_SETUP e depois nos caminhos padrao; instalar:
#
#   winget install --id JRSoftware.InnoSetup
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

Push-Location $root
try {
    $iscc = $env:INNO_SETUP
    if (-not $iscc) {
        $iscc = @(
            "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
            "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
            "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
        ) | Where-Object { Test-Path $_ } | Select-Object -First 1
    }
    if (-not $iscc) { $iscc = (Get-Command iscc -ErrorAction SilentlyContinue).Source }
    if (-not $iscc) {
        throw "Inno Setup nao encontrado. Instale com 'winget install --id JRSoftware.InnoSetup' ou aponte `$env:INNO_SETUP para o ISCC.exe."
    }

    & "$root\package.ps1"

    # O Inno so aceita .ico em SetupIconFile e o que temos sao PNGs. Um ICO e
    # cabecalho + indice + os arquivos crus, e o Windows le entrada PNG desde o
    # Vista -- entao da para montar sem decodificar nada.
    $pngs = 'icons\icon16.png', 'icons\icon32.png', 'icons\icon48.png', 'icons\icon128.png'
    $dados = New-Object System.Collections.ArrayList
    foreach ($f in $pngs) { [void]$dados.Add([System.IO.File]::ReadAllBytes($f)) }

    $ms = New-Object System.IO.MemoryStream
    $bw = New-Object System.IO.BinaryWriter($ms)
    $bw.Write([uint16]0)                 # reservado
    $bw.Write([uint16]1)                 # 1 = icone
    $bw.Write([uint16]$dados.Count)
    $offset = 6 + 16 * $dados.Count
    foreach ($d in $dados) {
        # Largura do PNG: IHDR, big-endian, bytes 16..19. Todas aqui cabem em um
        # byte -- e no indice do ICO 256 seria escrito como 0 de qualquer jeito.
        $bw.Write([byte]$d[19]); $bw.Write([byte]$d[19])
        $bw.Write([byte]0); $bw.Write([byte]0)
        $bw.Write([uint16]1); $bw.Write([uint16]32)
        $bw.Write([uint32]$d.Length); $bw.Write([uint32]$offset)
        $offset += $d.Length
    }
    foreach ($d in $dados) { $bw.Write($d) }
    $bw.Flush()
    [System.IO.File]::WriteAllBytes("$root\obj\LeTanki.ico", $ms.ToArray())
    $bw.Dispose(); $ms.Dispose()

    & $iscc '/Qp' 'installer.iss'
    if ($LASTEXITCODE -ne 0) { throw "ISCC falhou (exit $LASTEXITCODE)" }

    $setup = Get-Item 'dist\LeTanki-setup.exe'
    Write-Host "dist\LeTanki-setup.exe  ($([math]::Round($setup.Length/1MB,1)) MB)"
} finally { Pop-Location }

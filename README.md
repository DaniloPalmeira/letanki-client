# letanki-client

O cliente Flash/AIR legado do Tanki Online — o que fica **no PC do usuário**
quando ele instala o LeTanki. Aqui ficam o fonte do que é nosso e a única
dependência binária que não dá para gerar; o cliente inteiro sai do
`package.ps1`.

Todo o resto do jogo (`Prelauncher.swf`, `AlternativaLoader.swf`, `entrance`,
`game`, `hardware`/`software`, localização) é baixado do CDN a cada abertura e
**não** está aqui.

## Estrutura

```
application.xml                   # descritor AIR: CDN e parâmetros do loader
icons/                            # 16/32/48/128, viram o ícone do exe

src/                              # fonte do StandaloneLoader-2.0.swf
  assets/logo.png
  projects/tanks/clients/fp10/StandaloneLoader/
    StandaloneLoader.as           # carrega o Prelauncher do CDN
    Alert.as
    LocalizedTexts.as

deps/
  Adobe AIR/Versions/1.0/         # runtime AIR 22.0.0.153 captive, 27 MB

build.ps1                         # src/ -> obj/StandaloneLoader-2.0.swf
package.ps1                       # tudo -> build/
installer.iss                     # script do Inno Setup
installer.ps1                     # build/ -> dist/LeTanki-setup.exe
```

A saída sai em três pastas, todas fora do git: `obj/` é o SWF intermediário,
`build/` é o cliente montado e `dist/` é o instalador.

`deps/` é a única coisa versionada que não se gera: o runtime captive que veio
no instalador original. O resto do cliente — exe, `META-INF`, `mimetype`, SWF —
é produzido na hora.

O fonte em `src/` foi descompilado do SWF original (JPEXS/ffdec) e corrigido
até recompilar. Não é o fonte histórico: nomes de locais e parâmetros não
existem mais no bytecode, então qualquer nome ali é inferido.

## Montar o cliente

```powershell
powershell -File package.ps1
```

Sai em `build/`, pronto para rodar. O script compila o SWF (chamando o
`build.ps1`), manda o `adt` empacotar — exe, `META-INF` e `mimetype` — e troca
o runtime no fim: o `adt` embarca o **AIR 32** do próprio SDK, e o que este
cliente sempre rodou é o **AIR 22.0.0.153** de `deps/`.

Para compilar só o SWF, sem empacotar:

```powershell
powershell -File build.ps1
```

Precisa do **Apache Flex 4.16.1 com overlay do Adobe AIR SDK 32**. Os dois
scripts procuram em `$env:FLEX_SDK` e depois em `tools\flex-sdk` (fora do git).
Para apontar para um SDK que já existe em outro lugar:

```powershell
cmd /c mklink /J tools\flex-sdk "C:\caminho\para\flex-sdk"
```

O caminho do SDK pode ter espaço; o do repositório não — o parser de linha de
comando do `mxmlc` quebra em caminho absoluto com espaço, e por isso os scripts
rodam tudo relativo à raiz.

## Instalador

```powershell
powershell -File installer.ps1
```

Sai em `dist/LeTanki-setup.exe`. O script roda o `package.ps1` antes, para o
instalador nunca empacotar um build velho.

Precisa do **Inno Setup 6**, que é de propósito: o instalador original do
LeTanki também era Inno — o `unins000.exe`/`unins000.dat` que ele deixa no
disco é a assinatura disso. O `adt` tem `-target native`, mas não serve: ele
embarca o runtime do próprio SDK, e este cliente roda no AIR 22 de `deps/`.

```powershell
winget install --id JRSoftware.InnoSetup
```

O `installer.ps1` procura o `ISCC.exe` em `$env:INNO_SETUP` e depois nos
caminhos padrão de instalação.

Instala em `C:\Program Files\LeTanki Online`, o que pede elevação. Dá para
instalar ali porque o cliente não escreve ao lado do exe: o que ele guarda vai
para `%APPDATA%\LeTanki`. O `ArchitecturesInstallIn64BitMode` está ligado só
para o `{autopf}` não cair em `Program Files (x86)`, que é onde um instalador
de 32 bits aterrissa por padrão.

O ícone do setup sai de `icons/`, montado pelo `installer.ps1`: um `.ico` é
cabeçalho, índice e os arquivos crus, e o Windows lê entrada PNG desde o Vista
— não precisa converter nada.

O `AppId` no `installer.iss` é fixo: é por ele que o Windows reconhece uma
instalação existente para atualizar em vez de duplicar.

## Como o cliente sobe

O `LeTanki.exe` lê `META-INF/AIR/application.xml` (cópia verbatim do
`application.xml` da raiz), que abre o `StandaloneLoader-2.0.swf` com os
endereços de produção na query string:

```
StandaloneLoader-2.0.swf
  ?prelauncher=https://res.letanki.com/Prelauncher.swf
  &swf=https://res.letanki.com/AlternativaLoader.swf
  &config=https://res.letanki.com/config.xml
  &resources=https://res.letanki.com
  &balancer=https://res.letanki.com/s/status.js
  &prefix=s&locale=pt_BR
```

O loader baixa e executa o `Prelauncher.swf`; dali em diante tudo vem do CDN.
Trocar o CDN é editar essa linha do `application.xml` — nada precisa
recompilar para isso.

## O exe

O `LeTanki.exe` não tem código nosso: é o `CaptiveAppEntry.exe` do SDK do AIR
com os ícones injetados na seção `.rsrc`. Quem faz isso é o `adt -target
bundle` — o `adl` só *roda* um app a partir do descritor, nunca empacota.
Conferido seção a seção contra o template do SDK: `.text`, `.rdata`, `.data` e
`.reloc` saem idênticos, só a `.rsrc` muda.

Ele não sai igual ao exe do instalador original, e não tem como: aquele foi
empacotado com AIR 22.0.0.153 e o SDK aqui é o AIR 32.0.0.116 — templates
diferentes, 69.432 contra 82.944 bytes. Testado: o stub do 32 sobe sobre o
runtime captive 22, abre a janela e carrega o jogo.

## Notas

- **Os ícones servem ao exe, não à execução.** O `adt` recusa empacotar sem
  eles (`error 303`) e injeta os quatro como `RT_ICON` no `.rsrc`. É de lá que
  sai o ícone do arquivo, da janela e da barra de tarefas: removendo a pasta
  `icons/` do cliente montado, ele sobe igual e a janela mantém o mesmo ícone —
  comparados os bitmaps extraídos por `WM_GETICON`, idênticos. O `LeTanki.exe`
  do instalador original carregava ainda os quatro PNGs crus (IDs 1–4,
  630/1835/2626/9290 bytes) além dos `RT_ICON` em BMP do `adt`: alguém injetava
  os PNGs no binário depois de empacotar, que é o mesmo truque do `.ico` do
  setup.
- **SWF v17 (Flash Player 11.4).** O runtime de `deps/` é o AIR 22.0.0.153, que
  recusa SWF de versão mais nova. O `build.ps1` fixa `-swf-version=17`; não
  aumentar sem testar no cliente de verdade.
- **`+configname=air` é obrigatório.** O loader usa `NativeApplication` e
  `Screen`, que só existem no perfil AIR.
- **A assinatura é auto assinada e não vale nada.** A original era da
  Alternativa Game Ltd e não há como reproduzir sem a chave privada dela. O AIR
  não valida isso ao subir: testado, o cliente abre normal com o
  `signatures.xml` gerado aqui, de 3,7 KB contra os 71 KB do original. O
  `META-INF/AIR/hash` é derivado do certificado; com o descritor no namespace
  4.0 ele não entra no caminho da pasta de dados, que é só `%APPDATA%\LeTanki`.
- **O certificado fica fixo em `adt-cert.p12`.** Não porque valha alguma coisa,
  mas porque um certificado novo a cada rodada mudaria o `hash` e o
  `signatures.xml` toda vez. Apagar o arquivo só gera outra identidade.
- **O exe muda a cada build.** O `adt` distribui os IDs dos ícones no `.rsrc` em
  ordem arbitrária, então duas rodadas seguidas dão exes diferentes mesmo sem
  nenhuma entrada ter mudado.
- **Uma instância por vez.** Se já houver um LeTanki aberto, mesmo de outra
  pasta, o processo novo sai na hora com código 0 e sem abrir janela: o AIR
  admite uma instância por `<id>` do descritor.
- **O SWF recompilado não é o original.** Contra outro build nosso a única
  diferença é o `dc:date` do metadata XMP, mas contra o binário que vinha no
  instalador são 56.547 bytes em vez de 62.384. E o logo não sai byte a byte:
  no original ele é `DefineBitsLossless2` (bitmap ARGB pré-multiplicado), o
  ffdec desfaz a pré-multiplicação ao extrair e o compilador refaz ao embutir.
  Medido: 8329 de 90000 pixels mudam, nenhum deles opaco, erro só em borda
  antisserrilhada.
- **O payload original está no histórico.** A pasta `app/`, byte a byte do
  instalador, foi removida em favor de gerar tudo. Continua recuperável:
  `git show fefadaa:app/LeTanki.exe`, `git show fefadaa:app/META-INF/signatures.xml`.

## Fora do repositório

- `unins000.exe` / `unins000.dat` — o desinstalador do Inno Setup, gerado na
  máquina de quem instala. Não é payload.
- `adt-cert.p12` — certificado auto assinado, gerado na primeira execução do
  `package.ps1`.
- `tools/flex-sdk` — SDK de terceiros, ~30 MB.
- `obj/`, `build/`, `dist/` — saída de compilação: o SWF intermediário, o
  cliente montado e o instalador.

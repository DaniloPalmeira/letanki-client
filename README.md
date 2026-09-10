# letanki-client

O cliente Flash/AIR - o que fica **no PC do usuário**
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

CODE-SIGNING-POLICY.md            # quem assina os binários, e como conferir
docs/index.html                   # página do projeto e de download
```

A saída sai em três pastas, todas fora do git: `obj/` é o SWF intermediário,
`build/` é o cliente montado e `dist/` é o instalador.

`deps/` é a única coisa versionada que não se gera: o runtime captive que veio
no instalador original. O resto do cliente — exe, `META-INF`, `mimetype`, SWF —
é produzido na hora.

O `src/` é código nosso, escrito do zero a partir do contrato observável — os
parâmetros que o descritor entrega e o que o loader precisa fazer com eles. Não
é descompilação: a versão anterior, essa sim tirada do SWF original com
JPEXS/ffdec, está no histórico, em `ef5abd1`.

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

## O loader

O `StandaloneLoader-2.0.swf` faz uma coisa só: mostra o logo, baixa o
`Prelauncher.swf` do endereço que veio na query string e entrega a tela para
ele. São 248 linhas em três arquivos — `StandaloneLoader.as`, `Alert.as` e
`LocalizedTexts.as`.

O detalhe que justifica ele existir está em como o Prelauncher é carregado. Um
`Loader.load()` apontado para `https://` põe o SWF no sandbox remoto, e de lá
ele não pode encostar no `Stage`, que pertence ao nosso SWF — dá
`SecurityError #2070` no instante em que o Prelauncher tenta montar a tela.
Então os bytes vêm por `URLLoader` e são executados por `loadBytes()` com
`allowLoadBytesCodeExecution`, o que roda tudo no sandbox da aplicação.

É de lá também que o Prelauncher enxerga `stage.loaderInfo.parameters`, que são
os parâmetros do descritor. Não é preciso repassar nada na mão.

Toda exceção não tratada cai num handler que a mostra na tela. Sem isso, um erro
no loader vira janela preta muda: o AIR não tem console para onde reclamar.

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

- **De `deps/` só sai o que é provadamente inútil.** O `CaptiveAppEntry.exe` que
  vinha no runtime foi removido: o nosso exe *é* ele, vindo do SDK 32. O resto
  fica. O cliente sobe sem a `Resources/` inteira, mas isso não prova nada:
  `WebKit.dll` e `NPSWF32.dll` só são carregados quando o app abre um
  `HTMLLoader`/`StageWebView`, e a falta deles apareceria mais tarde, não no
  arranque.
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

## Página do projeto

`docs/index.html` é a página de download, servida pelo GitHub Pages em
**Settings → Pages → Source: `main` / `docs`**. É uma página só, sem build e sem
dependência externa — o ícone vai embutido como data URI.

Ela descreve o que o cliente faz, o que ele acessa na rede e como desinstalar.
Não é enfeite: essas três coisas são requisitos da candidatura ao SignPath
Foundation, junto com a [política de assinatura](CODE-SIGNING-POLICY.md).

## Licença

[MIT](LICENSE) — copie, modifique e redistribua à vontade, desde que o aviso de
copyright e o texto da licença venham junto.

Ela cobre o que é nosso: `src/`, `icons/`, `application.xml`, os scripts e o
`installer.iss`. **Não** cobre `deps/Adobe AIR/`, que é o runtime captive do
Adobe AIR, redistribuído sob os termos da Adobe e não sob a MIT. Dentro dele vai
WebKit sob LGPL, com os avisos em
`deps/Adobe AIR/Versions/1.0/Resources/WebKit/`.

## Fora do repositório

- `unins000.exe` / `unins000.dat` — o desinstalador do Inno Setup, gerado na
  máquina de quem instala. Não é payload.
- `adt-cert.p12` — certificado auto assinado, gerado na primeira execução do
  `package.ps1`.
- `tools/flex-sdk` — SDK de terceiros, ~30 MB.
- `obj/`, `build/`, `dist/` — saída de compilação: o SWF intermediário, o
  cliente montado e o instalador.

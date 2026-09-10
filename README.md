# letanki-client

O que fica **no PC do usuário** quando ele instala o LeTanki — o cliente
Flash/AIR legado do Tanki Online. Este repositório é a imagem do payload do
instalador, mais o fonte editável do único SWF que vai junto.

Todo o resto do jogo (`Prelauncher.swf`, `AlternativaLoader.swf`, `entrance`,
`game`, `hardware`/`software`, localização) é baixado do CDN a cada abertura e
**não** está aqui.

## Estrutura

```
app/                              # imagem do que o instalador escreve no disco
  LeTanki.exe                     # launcher
  StandaloneLoader-2.0.swf        # o único SWF local (compilado de src/)
  META-INF/AIR/application.xml    # descritor: CDN e parâmetros do loader
  META-INF/signatures.xml         # assinatura do pacote .air original
  icons/                          # 16/32/48/128
  Adobe AIR/Versions/1.0/         # runtime AIR 22.0.0.153 embarcado (captive)

src/                              # fonte do StandaloneLoader-2.0.swf
  assets/logo.png
  projects/tanks/clients/fp10/StandaloneLoader/
    StandaloneLoader.as           # carrega o Prelauncher do CDN
    Alert.as
    LocalizedTexts.as

build.ps1                         # src/ -> build/StandaloneLoader-2.0.swf
```

O fonte em `src/` foi descompilado do SWF original (JPEXS/ffdec) e corrigido
até recompilar. Não é o fonte histórico: nomes de locais e parâmetros não
existem mais no bytecode, então qualquer nome ali é inferido.

## Compilar o SWF

```powershell
powershell -File build.ps1            # compila em build/
powershell -File build.ps1 -Install   # compila e troca o SWF em app/
```

O `-Install` é separado de propósito: compilar só para conferir não pode sujar
`app/`, que é a imagem do que vai instalado.

Precisa do **Apache Flex 4.16.1 com overlay do Adobe AIR SDK 32**. O build
procura em `$env:FLEX_SDK` e depois em `tools\flex-sdk` (fora do git). Para
apontar para um SDK que já existe em outro lugar:

```powershell
cmd /c mklink /J tools\flex-sdk "C:\caminho\para\flex-sdk"
```

O caminho do SDK pode ter espaço; o do repositório não — o parser de linha de
comando do `mxmlc` quebra em caminho absoluto com espaço, e por isso o
`build.ps1` roda tudo relativo à raiz.

## Como o cliente sobe

O `LeTanki.exe` lê `META-INF/AIR/application.xml`, que abre o
`StandaloneLoader-2.0.swf` com os endereços de produção na query string:

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
Trocar o CDN é editar essa linha do `application.xml` — nada no SWF é preciso
recompilar para isso.

## Notas

- **SWF v17 (Flash Player 11.4).** O runtime embarcado é o AIR 22.0.0.153, que
  recusa SWF de versão mais nova. O `build.ps1` fixa `-swf-version=17`; não
  aumentar sem testar no `LeTanki.exe` de verdade.
- **`+configname=air` é obrigatório.** O loader usa `NativeApplication` e
  `Screen`, que só existem no perfil AIR.
- **A assinatura já está inválida, e não faz diferença.** Nenhum dos digests de
  `META-INF/signatures.xml` bate com os arquivos do pacote — nem o
  `application.xml`, nem os ícones, nem o SWF —, e o `mimetype` que o `.air`
  original tinha nem existe mais aqui. O instalador foi remontado depois de
  assinado e roda assim mesmo, então substituir o SWF não quebra a execução.
  A assinatura fica versionada como registro do pacote original.
- **O logo não sai byte a byte.** No SWF original ele é `DefineBitsLossless2`
  (bitmap ARGB pré-multiplicado); o ffdec desfaz a pré-multiplicação ao extrair
  e o compilador refaz ao embutir. Medido: 8329 de 90000 pixels mudam, nenhum
  deles opaco, erro só em borda antisserrilhada. Se um dia precisar de
  fidelidade exata, substituir a tag no SWF em vez de recompilar.
- **Recompilar dá bytecode equivalente, não idêntico.** Contra o build de
  referência, a única diferença é o `dc:date` do metadata XMP.

## Fora do repositório

- `unins000.exe` / `unins000.dat` — o desinstalador do Inno Setup, gerado na
  máquina de quem instala. Não é payload.
- `tools/flex-sdk` — SDK de terceiros, ~30 MB.
- `build/` — saída de compilação.

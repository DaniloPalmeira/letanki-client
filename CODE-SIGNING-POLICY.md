# Política de assinatura de código

Este documento descreve quem assina os binários do LeTanki, o que é assinado e
como verificar uma assinatura.

## Estado atual

**Os binários ainda não são assinados.** A candidatura ao [SignPath
Foundation](https://signpath.org/) está pendente; até que um certificado seja
emitido, o `LeTanki-setup.exe` e o `LeTanki.exe` são distribuídos sem
assinatura, e o Windows exibirá o aviso do SmartScreen ao executá-los.

Este documento descreve a política que passa a valer quando a assinatura entrar
em operação. Ele existe desde já porque a publicação da política é um dos
requisitos da candidatura.

## Time e papéis

O projeto é mantido por uma pessoa, que acumula todos os papéis:

| papel | responsável |
|---|---|
| Desenvolvimento e manutenção do código | Danilo Palmeira |
| Autorização de cada assinatura | Danilo Palmeira |
| Publicação das releases | Danilo Palmeira |

Não há outros committers com acesso de escrita ao repositório nem à conta de
assinatura. Se isso mudar, este documento muda junto, antes de o acesso ser
concedido.

Autenticação multifator é obrigatória para o repositório de origem e para a
conta de assinatura, sem exceção.

## O que é assinado

Apenas os artefatos de release:

- `LeTanki-setup.exe` — o instalador, produzido por `installer.ps1`
- `LeTanki.exe` — o launcher dentro dele, produzido por `package.ps1`

Builds de desenvolvimento não são assinados. Assinar cada build seria contra o
próprio interesse do projeto: a reputação do SmartScreen se acumula por binário,
e uma enxurrada de executáveis diferentes a dilui.

## De onde vêm os binários

Todo artefato assinado é compilado a partir do fonte deste repositório, pelos
scripts que estão nele:

```
build.ps1      src/            -> obj/StandaloneLoader-2.0.swf
package.ps1    obj/ + deps/    -> build/          (o cliente)
installer.ps1  build/          -> dist/LeTanki-setup.exe
```

Nada é assinado sem passar por esse caminho. Binário recebido de terceiro,
compilado em outra máquina ou reempacotado à mão não é assinado em hipótese
alguma.

A única exceção declarada é o runtime do Adobe AIR em `deps/`, que é
redistribuído como veio da Adobe — já assinado por ela, e não por nós. Ele não é
recompilado nem modificado.

## Aprovação

Cada assinatura é aprovada manualmente, por release. Não há assinatura
automática disparada por commit, merge ou pipeline.

## Como verificar

No Windows, com o arquivo baixado:

```powershell
Get-AuthenticodeSignature .\LeTanki-setup.exe | Format-List Status, SignerCertificate
```

`Status` deve ser `Valid`. Pelo Explorer, o mesmo dado está em Propriedades →
Assinaturas Digitais.

Enquanto a assinatura não estiver em operação, o resultado será `NotSigned` —
o que é o esperado, e não indica adulteração.

## Reportando um problema

Binário assinado que não corresponda a uma release publicada aqui, ou
assinatura que apareça em artefato que não saiu deste repositório, deve ser
reportado por issue no repositório. Um certificado comprometido é revogado antes
de qualquer outra providência.

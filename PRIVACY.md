# Política de privacidade

Este documento descreve quais dados o cliente do LeTanki (o launcher e o
instalador distribuídos neste repositório) coleta, guarda e envia.

## Resumo

O cliente não coleta dados pessoais, não tem telemetria, anúncios nem
rastreadores, e não envia nada a terceiros.

## O que fica no seu computador

- **Configurações do cliente**, em `%APPDATA%\LeTanki`: preferências locais. Elas nunca saem da máquina. Para apagá-las, remova
  essa pasta; o desinstalador não a remove.
- **Cache de recursos do jogo**, gravado pelo runtime Adobe AIR, para não baixar
  os mesmos arquivos toda vez.

## Com quem o cliente se conecta

O cliente acessa apenas os servidores do projeto, em `letanki.com` e seus
subdomínios (por exemplo, `res.letanki.com`), para baixar o jogo e se conectar a
ele. Como em qualquer conexão de rede, esses servidores recebem o seu endereço IP.

O cliente não se conecta a serviços de análise, publicidade ou redes sociais.

## Conta e dados do jogo

O login, o apelido e o progresso no jogo são tratados pelos servidores do
LeTanki, não pelo cliente. O cliente apenas exibe o jogo e repassa o que você
digita nele.

## Mudanças

Qualquer mudança no que o cliente coleta ou envia será registrada neste
documento, no mesmo commit que a introduzir. O histórico fica disponível no
[GitHub](https://github.com/DaniloPalmeira/letanki-client/commits/main/PRIVACY.md).

## Contato

Dúvidas sobre privacidade podem ser enviadas como
[issue no GitHub](https://github.com/DaniloPalmeira/letanki-client/issues).

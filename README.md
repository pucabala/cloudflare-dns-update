# Cloudflare DNS Update Scripts

Este repositório contém scripts para atualizar registros DNS dinâmicos no Cloudflare em uma instância Google Clound VPS Ubuntu . Os scripts foram projetados para automatizar o processo de atualização de registros DNS para refletir o IP público atual do servidor.

## Estrutura do Repositório

```
/opt/cloudflare-dns-update/
├── config/
│   └── config.json                    # Arquivo de configuração gerado pelo script de configuração
├── scripts/
│   ├── configure.sh                    # Script para configurar e gerar o arquivo de configuração
│   └── update-dns.sh                   # Script para atualizar os registros DNS
├── logs/
│   └── update-dns.log                  # Arquivo de log para o script de atualização
└── install-cloudflare-dns-update.sh    # Arquido de instalação

```

## Dependências

Antes de executar os scripts, certifique-se de que você tem as seguintes dependências instaladas:

1. **curl** - Para fazer chamadas HTTP.
2. **jq** - Para processar JSON.
3. **cron** - Para agendar tarefas.

Instale as dependências com o seguinte comando:

```bash
sudo apt update
sudo apt install curl jq cron
```

## Configuração

### Script de Configuração (`configure.sh`)

Este script gera um arquivo de configuração (`config.json`) que é usado pelo script de atualização. Execute o script e siga as instruções para fornecer seu token da API Cloudflare e selecionar os registros DNS que deseja atualizar.

```bash
sudo /opt/cloudflare-dns-update/scripts/configure.sh
```

O script solicitará o token da API Cloudflare e listará os registros DNS disponíveis. Escolha os registros que deseja atualizar e o script criará um arquivo `config.json` no diretório `/opt/cloudflare-dns-update/config/`.

### Script de Atualização (`update-dns.sh`)

O script de atualização é responsável por verificar o IP público atual e atualizar os registros DNS no Cloudflare se necessário.

```bash
sudo /opt/cloudflare-dns-update/scripts/update-dns.sh
```

## Agendamento do Script

Para garantir que o script de atualização seja executado a cada 6 minutos e seja iniciado automaticamente no boot, configure o cron para executar o script e adicione uma entrada no `crontab`.

### Adicionar ao `crontab`

1. Abra o crontab para edição:

    ```bash
    sudo crontab -e
    ```

2. Adicione as seguintes linhas ao final do arquivo para agendar o script de atualização:

    ```bash
    @reboot /opt/cloudflare-dns-update/scripts/update-dns.sh >> /opt/cloudflare-dns-update/logs/update-dns.log 2>&1
    */6 * * * * /opt/cloudflare-dns-update/scripts/update-dns.sh >> /opt/cloudflare-dns-update/logs/update-dns.log 2>&1
    ```

   A primeira linha garante que o script seja executado após o reboot, e a segunda linha agenda a execução a cada 6 minutos. Os logs serão gravados no arquivo `/opt/cloudflare-dns-update/logs/update-dns.log`.

## Permissões

Certifique-se de que o script tenha permissões de execução e que o diretório de logs tenha permissões apropriadas:

```bash
sudo chmod +x /opt/cloudflare-dns-update/scripts/*.sh
sudo chmod -R 755 /opt/cloudflare-dns-update/logs
```

## Contribuição

Se você deseja contribuir com melhorias ou relatar problemas, sinta-se à vontade para abrir uma issue ou um pull request neste repositório.

## Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

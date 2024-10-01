#!/bin/bash


# Variáveis
REPO_URL="https://github.com/pucabala/cloudflare-dns-update.git"
INSTALL_DIR="/opt/cloudflare-dns-update"
LOG_DIR="$INSTALL_DIR/logs"
CONFIG_DIR="$INSTALL_DIR/config"
SCRIPTS_DIR="$INSTALL_DIR/scripts"


# Passo 1: Atualizar pacotes e instalar dependências
echo "Atualizando pacotes e instalando dependências..."
sudo apt update && sudo apt install -y curl jq cron git


# Passo 2: Clonar o repositório
echo "Clonando repositório..."
if [ ! -d "$INSTALL_DIR" ]; then
    sudo git clone "$REPO_URL" "$INSTALL_DIR"
else
    echo "Repositório já existe em $INSTALL_DIR."
fi


# Passo 3: Garantir que os scripts tenham permissões de execução
echo "Configurando permissões..."
sudo chmod +x $SCRIPTS_DIR/*.sh
sudo mkdir -p $LOG_DIR
sudo chmod -R 755 $LOG_DIR


# Passo 4: Executar o script de configuração
echo "Executando o script de configuração..."
sudo $SCRIPTS_DIR/configure.sh


# Passo 5: Configurar o cron para execução automática
echo "Configurando o cron..."
(crontab -l 2>/dev/null; echo "@reboot $SCRIPTS_DIR/update-dns.sh >> $LOG_DIR/update-dns.log 2>&1") | sudo crontab -
(crontab -l 2>/dev/null; echo "*/6 * * * * $SCRIPTS_DIR/update-dns.sh >> $LOG_DIR/update-dns.log 2>&1") | sudo crontab -


# Passo 6: Finalização
echo "Instalação e configuração concluídas!"
echo "Os logs podem ser encontrados em $LOG_DIR/update-dns.log"

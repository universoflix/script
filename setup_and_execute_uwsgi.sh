#!/bin/bash

# Função para verificar se um pacote está instalado
check_package() {
    dpkg -s $1 &> /dev/null
}

# Verificar se o Python 3 está instalado
if ! check_package "python3"; then
    echo "Instalando Python 3..."
    sudo apt update
    sudo apt install python3 -y
fi

# Instalar as dependências necessárias para compilar o uWSGI
echo "Instalando as dependências necessárias para compilar o uWSGI..."
sudo apt update
sudo apt install build-essential python3-dev -y

# Instalar o pacote 'uwsgi-plugin-python3'
echo "Instalando o pacote 'uwsgi-plugin-python3'..."
sudo apt install uwsgi-plugin-python3 -y

# Recompilar o uWSGI com suporte ao plugin Python3
echo "Recompilando o uWSGI com suporte ao plugin Python3..."
sudo python3 -m pip install uwsgi --no-cache-dir --force-reinstall --install-option="--plugin=python3"

# Baixar o arquivo app.py na pasta raiz (root)
echo "Baixando o arquivo app.py na pasta raiz..."
wget -O /root/app.py https://raw.githubusercontent.com/universoflix/script/main/app.py

# Executar o uWSGI
echo "Executando o uWSGI..."
uwsgi --http-socket :45678 --plugin python3 --module app:app

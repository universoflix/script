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

# Instalar o uWSGI e Flask usando o pip
if ! python3 -m pip show uwsgi &> /dev/null; then
    echo "Instalando uWSGI e Flask..."
    sudo apt update
    sudo apt install python3-pip -y
    sudo python3 -m pip install uwsgi flask
fi

# Baixar o arquivo app.py
wget -O app.py https://raw.githubusercontent.com/universoflix/script/main/app.py

# Executar o uWSGI
echo "Executando o uWSGI..."
uwsgi --http-socket :45678 --plugin python3 --wsgi-file app.py

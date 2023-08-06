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

# Baixar o arquivo app.py
wget -O app.py https://raw.githubusercontent.com/universoflix/script/main/app.py

# Instalar o uWSGI e Flask
if ! check_package "uwsgi"; then
    echo "Instalando uWSGI..."
    sudo apt update
    sudo apt install uwsgi -y
fi

if ! python3 -c "import flask" &> /dev/null; then
    echo "Instalando Flask e suas dependências..."
    sudo apt update
    sudo apt install python3-flask -y
fi

# Executar o uWSGI
echo "Executando o uWSGI..."
uwsgi --http :45678 --wsgi-file app.py

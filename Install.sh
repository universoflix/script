#!/bin/bash

# Função para verificar se um pacote está instalado
check_package() {
    dpkg -s $1 &> /dev/null
}

# Baixar o arquivo 'app.py' do Git
wget -O app.py https://raw.githubusercontent.com/universoflix/script/main/app.py

    echo "Instalando Python 3..."
    sudo apt update
    sudo apt install python3.7 -y
fi
    echo "Instalando Flask e suas dependências..."
    sudo apt update
    sudo apt install python3-flask -y
    sudo pip3 install flask_cors
fi

# Executar o arquivo
echo "Executando o arquivo app.py..."
python3 app.py


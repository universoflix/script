#!/bin/bash

# Obter o diretório atual do script
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Atualizar o sistema
sudo apt-get update

# Instalar o Python e o Flask
sudo apt-get install python3 python3-pip -y
pip3 install flask

# Instalar o WireGuard
sudo apt-get install wireguard-tools -y

# Criar um diretório para o servidor Flask
sudo mkdir /opt/wireguard_web
sudo chown $USER:$USER /opt/wireguard_web

# Criar um diretório para o servidor web do Flask
sudo mkdir /opt/wireguard_web/templates

# Obter o endereço IP local do servidor
server_ip=$(hostname -I | awk '{print $1}')

# Copiar os arquivos do servidor Flask e do HTML para o diretório correto
cp $script_dir/app.py /opt/wireguard_web/
cp $script_dir/templates/index.html /opt/wireguard_web/templates/

# Iniciar o servidor Flask em background
python3 /opt/wireguard_web/app.py &

echo "Instalação completa. O servidor web do WireGuard foi iniciado."
echo "Você pode acessar a interface web em http://$server_ip:5000"

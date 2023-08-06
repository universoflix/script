#!/bin/bash

# Obter o diretório atual do script
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Atualizar o sistema
sudo apt-get update

# Instalar as dependências do Pillow, Flask e qrcode
sudo apt-get install python3 python3-pip python3-dev libjpeg-dev zlib1g-dev -y
pip3 install flask pillow qrcode

# Instalar o WireGuard
sudo apt-get install wireguard-tools -y

# Create WireGuard directory and files
mkdir -p /etc/wireguard
touch /etc/wireguard/wg0.conf

# Create the users directory
mkdir -p /etc/wireguard/users

# Criar um diretório para o servidor Flask, se ainda não existir
sudo mkdir -p /opt/wireguard_web
sudo chown $USER:$USER /opt/wireguard_web

# Criar um diretório para o servidor web do Flask, se ainda não existir
sudo mkdir -p /opt/wireguard_web/templates

# Criar o arquivo app.py com o conteúdo do servidor Flask
cat << 'EOF' > /opt/wireguard_web/app.py
from flask import Flask, request, render_template, redirect, url_for
import qrcode
import os

app = Flask(__name__)

# Configurações do WireGuard
wg_interface = 'wg0'
wg_config_file = '/etc/wireguard/wg0.conf'
wg_users_dir = '/etc/wireguard/users'

# Função para criar um novo usuário no WireGuard
def create_user(username):
    os.system(f'wg genkey > {wg_users_dir}/{username}.private')
    os.system(f'wg pubkey < {wg_users_dir}/{username}.private > {wg_users_dir}/{username}.public')
    user_private_key = open(f'{wg_users_dir}/{username}.private').read().strip()
    user_public_key = open(f'{wg_users_dir}/{username}.public').read().strip()
    user_config = f'[Peer]\nPublicKey = {user_public_key}\nAllowedIPs = 10.0.0.2/32'
    with open(wg_config_file, 'a') as f:
        f.write(user_config)
    os.system(f'sudo wg set {wg_interface} peer {user_public_key} allowed-ips 10.0.0.2/32')
    return user_private_key

# Rota principal
@app.route('/')
def index():
    users = []
    for file in os.listdir(wg_users_dir):
        if file.endswith('.public'):
            users.append(file[:-7])
    return render_template('index.html', users=users)

# Rota para criar um novo usuário
@app.route('/create', methods=['POST'])
def create():
    username = request.form['username']
    private_key = create_user(username)
    qr = qrcode.make(private_key)
    qr.save(f'/opt/wireguard_web/static/{username}.png')
    return redirect(url_for('index'))

# Rota para apagar um usuário
@app.route('/delete/<username>')
def delete(username):
    os.system(f'sudo wg set {wg_interface} peer {username}.public remove')
    os.system(f'sudo wg-quick down {wg_interface}')
    os.system(f'sudo wg-quick up {wg_interface}')
    os.system(f'sudo rm {wg_users_dir}/{username}.private {wg_users_dir}/{username}.public')
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
EOF

# Criar o arquivo index.html com o conteúdo da página HTML
cat << 'EOF' > /opt/wireguard_web/templates/index.html
<!doctype html>
<html>
<head>
    <title>Gerenciamento de Usuários do WireGuard</title>
</head>
<body>
    <h1>Usuários do WireGuard</h1>
    <ul>
        {% for user in users %}
            <li>{{ user }} <a href="/delete/{{ user }}">Apagar</a></li>
        {% endfor %}
    </ul>
    <form action="/create" method="post">
        <label for="username">Novo Usuário: </label>
        <input type="text" id="username" name="username">
        <input type="submit" value="Criar">
    </form>
</body>
</html>
EOF

# Obter o endereço IP local do servidor
server_ip=$(hostname -I | awk '{print $1}')

# Verificar se o servidor Flask já está em execução
if [ "$(pgrep -f 'python3 /opt/wireguard_web/app.py')" ]; then
    echo "Parando o servidor Flask anterior..."
    sudo pkill -f 'python3 /opt/wireguard_web/app.py'
fi

# Copy the WireGuard web interface files
cp app.py /opt/wireguard_web/
mkdir -p /opt/wireguard_web/templates
cp templates/index.html /opt/wireguard_web/templates/

# Start WireGuard
wg-quick up wg0

# Start the WireGuard web interface using Flask
cd /opt/wireguard_web
python3 app.py

echo "Instalação completa. O servidor web do WireGuard foi iniciado."
echo "Você pode acessar a interface web em http://$server_ip:5000"

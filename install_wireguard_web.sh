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

# Diretório onde serão salvos os arquivos de configuração do WireGuard
wg_config_dir = '/etc/wireguard'

# Diretório onde serão salvos os arquivos de usuário do WireGuard
wg_users_dir = os.path.join(wg_config_dir, 'users')

# Diretório onde serão salvos os arquivos QR
static_dir = 'static'
if not os.path.exists(static_dir):
    os.makedirs(static_dir)

@app.route('/')
def index():
    users = []
    if os.path.exists(wg_users_dir):
        users = [f.replace('.conf', '') for f in os.listdir(wg_users_dir) if f.endswith('.conf')]
    return render_template('index.html', users=users)

@app.route('/create', methods=['POST'])
def create():
    username = request.form['username']
    private_key = request.form['private_key']
    address = request.form['address']
    allowed_ips = request.form['allowed_ips']

    # Código para criar o arquivo de configuração do usuário do WireGuard
    config_file_path = os.path.join(wg_users_dir, f'{username}.conf')
    with open(config_file_path, 'w') as f:
        f.write(f'[Interface]\nPrivateKey = {private_key}\nAddress = {address}\n')
        f.write(f'\n[Peer]\nAllowedIPs = {allowed_ips}')

    # Criação do código QR
    qr_data = f'[{username}]\nPrivateKey = {private_key}\nAddress = {address}\nAllowedIPs = {allowed_ips}\n'
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    qr.add_data(qr_data)
    qr.make(fit=True)

    # Salvando a imagem QR no diretório static
    qr_image_path = os.path.join(static_dir, f'{username}.png')
    qr.make_image().save(qr_image_path)

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

# Start WireGuard
wg-quick up wg0

# Start the WireGuard web interface using Flask
cd /opt/wireguard_web
python3 app.py

echo "Instalação completa. O servidor web do WireGuard foi iniciado."
echo "Você pode acessar a interface web em http://$server_ip:5000"

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

# Criar um diretório para o servidor Flask, se ainda não existir
sudo mkdir -p /opt/wireguard_web
sudo chown $USER:$USER /opt/wireguard_web

# Criar um diretório para o servidor web do Flask, se ainda não existir
sudo mkdir -p /opt/wireguard_web/templates

# Criar o arquivo app.py com o conteúdo do servidor Flask
cat << 'EOF' > /opt/wireguard_web/app.py
from flask import Flask, request, render_template, send_file
import subprocess
import qrcode
import os

app = Flask(__name__)

# Página inicial
@app.route('/')
def index():
    users = get_users()
    return render_template('index.html', users=users)

# Função para obter a lista de usuários do WireGuard
def get_users():
    users = []
    try:
        users_output = subprocess.check_output(['wg', 'show', 'wg0', 'allowed-ips'])
        for line in users_output.decode('utf-8').strip().split('\n'):
            username = line.split('\t')[0]
            config_file = f'/opt/wireguard_web/{username}.conf'
            qr_code_file = f'/opt/wireguard_web/{username}_qr.png'
            user = {
                'name': username,
                'config_file': config_file,
                'qr_code_file': qr_code_file,
            }
            users.append(user)
    except subprocess.CalledProcessError as e:
        print(f'Error: {str(e)}')
    return users

# Rota para criar um novo usuário
@app.route('/create', methods=['POST'])
def create_user():
    username = request.form['username']
    try:
        subprocess.run(['wg', 'set', 'wg0', 'peer', username, 'allowed-ips', '10.0.0.' + str(len(get_users()) + 2) + '/32'])
        generate_config(username)
        generate_qr_code(username)
    except subprocess.CalledProcessError as e:
        print(f'Error: {str(e)}')
    return index()

# Rota para apagar um usuário
@app.route('/delete/<username>')
def delete_user(username):
    try:
        subprocess.run(['wg', 'set', 'wg0', 'peer', username, 'remove'])
        remove_config(username)
        remove_qr_code(username)
    except subprocess.CalledProcessError as e:
        print(f'Error: {str(e)}')
    return index()

# Rota para baixar a configuração do usuário
@app.route('/download/<username>')
def download_config(username):
    config_file = f'/opt/wireguard_web/{username}.conf'
    return send_file(config_file, as_attachment=True)

# Rota para exibir o QR code do usuário
@app.route('/qr/<username>')
def view_qr_code(username):
    qr_code_file = f'/opt/wireguard_web/{username}_qr.png'
    return send_file(qr_code_file)

# Função para gerar a configuração do usuário
def generate_config(username):
    config_file = f'/opt/wireguard_web/{username}.conf'
    with open(config_file, 'w') as f:
        try:
            private_key = subprocess.check_output(['wg', 'genkey']).decode('utf-8').strip()
            public_key = subprocess.check_output(['echo', private_key, '|', 'wg', 'pubkey']).decode('utf-8').strip()
            address = f'10.0.0.{len(get_users()) + 2}/32'
            f.write(f'[Interface]\n')
            f.write(f'PrivateKey = {private_key}\n')
            f.write(f'Address = {address}\n')
            f.write(f'\n')
            f.write(f'[Peer]\n')
            f.write(f'PublicKey = {public_key}\n')
            f.write(f'AllowedIPs = 0.0.0.0/0\n')
            f.write(f'Endpoint = 129.148.48.221:51820\n')  # Replace with your server's public IP address
        except subprocess.CalledProcessError as e:
            print(f'Error: {str(e)}')

# Função para remover a configuração do usuário
def remove_config(username):
    config_file = f'/opt/wireguard_web/{username}.conf'
    if os.path.exists(config_file):
        os.remove(config_file)

# Função para gerar o QR code do usuário
def generate_qr_code(username):
    config_file = f'/opt/wireguard_web/{username}.conf'
    qr_code_file = f'/opt/wireguard_web/{username}_qr.png'
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4,
    )
    with open(config_file, 'r') as f:
        qr.add_data(f.read())
    qr.make(fit=True)
    img = qr.make_image(fill_color="black", back_color="white")
    img.save(qr_code_file)

# Função para remover o QR code do usuário
def remove_qr_code(username):
    qr_code_file = f'/opt/wireguard_web/{username}_qr.png'
    if os.path.exists(qr_code_file):
        os.remove(qr_code_file)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
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

# Iniciar o servidor Flask em background
python3 /opt/wireguard_web/app.py &

echo "Instalação completa. O servidor web do WireGuard foi iniciado."
echo "Você pode acessar a interface web em http://$server_ip:5000"

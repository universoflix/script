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

# Criar um diretório para o servidor Flask, se ainda não existir
sudo mkdir -p /opt/wireguard_web
sudo chown $USER:$USER /opt/wireguard_web

# Criar um diretório para o servidor web do Flask, se ainda não existir
sudo mkdir -p /opt/wireguard_web/templates

# Criar o arquivo app.py com o conteúdo do servidor Flask
cat << 'EOF' > /opt/wireguard_web/app.py
from flask import Flask, request, render_template
import subprocess

app = Flask(__name__)

# Página inicial
@app.route('/')
def index():
    users = get_users()
    return render_template('index.html', users=users)

# Função para obter a lista de usuários do WireGuard
def get_users():
    try:
        users_output = subprocess.check_output(['wg', 'show', 'wg0', 'allowed-ips'])
        users = [line.split('\t')[0] for line in users_output.decode('utf-8').strip().split('\n')]
        return users
    except subprocess.CalledProcessError:
        return []

# Rota para criar um novo usuário
@app.route('/create', methods=['POST'])
def create_user():
    username = request.form['username']
    subprocess.run(['wg', 'set', 'wg0', 'peer', username, 'allowed-ips', '10.0.0.' + str(len(get_users()) + 2) + '/32'])
    return index()

# Rota para apagar um usuário
@app.route('/delete/<username>')
def delete_user(username):
    subprocess.run(['wg', 'set', 'wg0', 'peer', username, 'remove'])
    return index()

if __name__ == '__main__':
    app.run(debug=True)
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

# Iniciar o servidor Flask em background
python3 /opt/wireguard_web/app.py &

echo "Instalação completa. O servidor web do WireGuard foi iniciado."
echo "Você pode acessar a interface web em http://$server_ip:5000"

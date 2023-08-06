from flask import Flask, request, jsonify
import subprocess

app = Flask(__name__)

@app.route('/', methods=['POST', 'GET'])
def create_account():
    if request.method == 'POST':
        login = request.form.get('login')
        senha = request.form.get('senha')
        limite = request.form.get('limite')
        validade = request.form.get('validade')

        if not all([login, senha, limite, validade]):
            return "Dados incompletos!", 400

        cmd = ['./SshturboMakeAccount.sh', login, senha, limite, validade]
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode != 0:
            return "Erro ao criar a conta.", 500

        return "Conta criada com sucesso!", 200

    elif request.method == 'GET':
        return "Este é um servidor Flask para criar contas. Envie uma solicitação POST com os campos 'login', 'senha', 'limite' e 'validade' para criar uma conta."

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=45678)

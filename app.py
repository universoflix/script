from flask import Flask, request, jsonify
import subprocess
import os

app = Flask(__name__)

@app.route('/', methods=['POST'])
def create_account():
    data = request.json  # Parse JSON data from the request

    login = data.get('login')
    senha = data.get('senha')
    limite = data.get('limite')
    validade = data.get('validade')

    if not all([login, senha, limite, validade]):
        return jsonify({"message": "Dados incompletos!"}), 400

    # Check if the script exists before executing it
    script_path = './SshturboMakeAccount.sh'
    if not os.path.exists(script_path):
        return jsonify({"message": "Erro: O script 'SshturboMakeAccount.sh' não foi encontrado!"}), 500

    # Validate 'limite' and 'validade' as integers
    if not limite.isdigit() or not validade.isdigit():
        return jsonify({"message": "Erro: 'limite' e 'validade' devem ser números inteiros!"}), 400

    cmd = [script_path, login, senha, limite, validade]
    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        return jsonify({"message": "Erro ao criar a conta."}), 500

    return jsonify({"message": "Conta criada com sucesso!"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=45678) 

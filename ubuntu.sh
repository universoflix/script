#!/bin/bash

# URL da imagem ISO do Ubuntu 18.04.6 Server para ARM64
iso_url="https://cdimage.ubuntu.com/releases/18.04/release/ubuntu-18.04.6-server-arm64.iso"

# Nome do arquivo da imagem ISO
iso_file="ubuntu-18.04.6-server-arm64.iso"

# Caminho onde a imagem ISO será salva
iso_path="/tmp/$iso_file"

# Verificar se o QEMU está instalado
if ! command -v qemu-system-arm &>/dev/null; then
    echo "QEMU não está instalado. Instale-o usando 'sudo apt-get install qemu-system-arm'."
    exit 1
fi

# Verificar se a imagem ISO já existe, se não, baixá-la
if [ ! -f "$iso_path" ]; then
    echo "Baixando a imagem ISO do Ubuntu Server ARM64..."
    wget -O "$iso_path" "$iso_url"
fi

# Iniciar a instalação em uma máquina virtual QEMU
qemu-system-arm -M virt -cpu cortex-a53 -m 1024 -drive file="$iso_path",if=none,index=0,id=drive0 -device virtio-blk-device,drive=drive0 -netdev user,id=net0 -device virtio-net-device,netdev=net0 -cdrom "$iso_path"

# Remover a imagem ISO após a instalação (opcional)
rm -f "$iso_path"

# Finalizado
echo "Instalação concluída."

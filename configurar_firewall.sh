#!/bin/bash

# Limpar todas as regras existentes
iptables -F

# Permitir tráfego TCP nas portas 22, 80, 8080 e 443
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# Permitir tráfego UDP nas portas 22, 80, 8080 e 443
iptables -A INPUT -p udp --dport 22 -j ACCEPT
iptables -A INPUT -p udp --dport 80 -j ACCEPT
iptables -A INPUT -p udp --dport 8080 -j ACCEPT
iptables -A INPUT -p udp --dport 443 -j ACCEPT

# Bloquear todo o tráfego de entrada não especificado acima
iptables -P INPUT DROP

# Salvar as regras para que sejam aplicadas após reinicialização do sistema
iptables-save > /etc/iptables/rules.v4

echo "Regras adicionadas com sucesso para permitir o tráfego nas portas 22, 80, 8080 e 443."

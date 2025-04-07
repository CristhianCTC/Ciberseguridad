#!/bin/bash


# ────────────────────────────────────────────────
# SCRIPT DE INSTALACIÓN Y CONFIGURACIÓN COMPLETA
# Elasticsearch + kibana
# Autor: Cristhian Torrico Castellón
# ────────────────────────────────────────────────


echo "📦 Instalación y configuración HTTPS Elasticsearch y Kibana"

sudo apt update && sudo apt upgrade -y
sudo apt install gnupg -y
sudo apt install -y apt-transport-https ca-certificates curl

echo "Preparativos para elasticsearch..."

curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

sudo apt update -y

echo "📦 Instalación elasticsearch y kibana"

sudo apt install elasticsearch kibana -y

echo "Configuración elasticsearch..."

sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service

sudo systemctl start elasticsearch

echo "Crear llaves kibana..."

kibana_token=$(sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana)

sudo /usr/share/kibana/bin/kibana-setup --enrollment-token $kibana_token

#Nos aseguramos que no haya espacios ni al principio ni al final
kibana_token=$(echo "$kibana_token" | xargs)

sudo systemctl stop kibana

echo "kibana-certs.zip" | sudo /usr/share/elasticsearch/bin/elasticsearch-certutil ca -pem

unzip /usr/share/elasticsearch/kibana-certs.zip -d /etc/kibana/

sudo mkdir -p /etc/kibana/certs

sudo mv /etc/kibana/ca/ca.crt /etc/kibana/ca/ca.key /etc/kibana/certs/

sudo chown -R kibana:kibana /etc/kibana/certs/
sudo chmod 600 /etc/kibana/certs/*

if ! grep -Fxq 'server.port: 5601' /etc/kibana/kibana.yml; then
  echo 'server.port: 5601' | sudo tee -a /etc/kibana/kibana.yml
fi

if ! grep -Fxq 'server.host: "0.0.0.0"' /etc/kibana/kibana.yml; then
  echo 'server.host: "0.0.0.0"' | sudo tee -a /etc/kibana/kibana.yml
fi

if ! grep -Fxq 'server.ssl.enabled: true' /etc/kibana/kibana.yml; then
  echo 'server.ssl.enabled: true' | sudo tee -a /etc/kibana/kibana.yml
fi

if ! grep -Fxq 'server.ssl.certificate: /etc/kibana/certs/ca.crt' /etc/kibana/kibana.yml; then
  echo 'server.ssl.certificate: /etc/kibana/certs/ca.crt' | sudo tee -a /etc/kibana/kibana.yml
fi

if ! grep -Fxq 'server.ssl.key: /etc/kibana/certs/ca.key' /etc/kibana/kibana.yml; then
  echo 'server.ssl.key: /etc/kibana/certs/ca.key' | sudo tee -a /etc/kibana/kibana.yml
fi


sudo systemctl restart kibana

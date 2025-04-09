
#!/bin/bash

echo "🔹 PASOS PARA REPARAR EL SERVIDOR"

# 1️⃣ Restaurar SSH a su puerto estándar (22)
echo "1️⃣ Restaurando SSH al puerto estándar (22)..."
sudo sed -i 's/^Port .*/Port 22/' /etc/ssh/sshd_config
sudo systemctl restart sshd
echo "✅ SSH reiniciado. Verificando puerto..."
sudo ss -tulnp | grep sshd

# 2️⃣ Poner en funcionamiento el sitio web
echo "2️⃣ Verificando instalación de Apache..."
sudo systemctl status httpd || {
    echo "Apache no está instalado. Instalando..."
    sudo yum install httpd -y
}
echo "✅ Iniciando y habilitando Apache..."
sudo systemctl start httpd
sudo systemctl enable httpd

echo "✅ Creando archivo del sitio web..."
sudo tee /var/www/html/index.html > /dev/null <<EOF
<html>
<head><title>Nuestro Sitio Web</title></head>
<body><h1>Nuestro Sitio Web</h1></body>
</html>
EOF

echo "✅ Asignando permisos..."
sudo chmod -R 755 /var/www/html
sudo chown -R apache:apache /var/www/html

# 3️⃣ Asegurar que el sitio web persista tras reinicio
echo "3️⃣ Configurando persistencia tras reinicio..."
sudo systemctl enable httpd
sudo setsebool -P httpd_can_network_connect on
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload

# 4️⃣ Configurar Apache en el puerto 80
echo "4️⃣ Verificando configuración de Apache para puerto 80..."
sudo sed -i 's/^Listen .*/Listen 80/' /etc/httpd/conf/httpd.conf
sudo systemctl restart httpd
echo "✅ Verificando puerto..."
sudo ss -tulnp | grep httpd

# 5️⃣ Corregir advertencia de ServerName
echo "5️⃣ Corrigiendo advertencia de ServerName..."
grep -q "ServerName localhost" /etc/httpd/conf/httpd.conf || echo "ServerName localhost" | sudo tee -a /etc/httpd/conf/httpd.conf
sudo systemctl restart httpd
echo "✅ Verificando configuración Apache..."
sudo apachectl configtest

# 6️⃣ Verificar acceso al sitio web
echo "6️⃣ Obteniendo IP del servidor..."
ip a | grep inet

echo "✅ Abre tu navegador y visita: http://<tu-ip>"

# 7️⃣ Ver errores si stopexam falla
echo "7️⃣ Verificando servicios fallidos..."
sudo systemctl --failed
echo "✅ Reiniciando servicios clave..."
sudo systemctl restart httpd

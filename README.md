# Assigngment1

#!/bin/bash


amazon-linux-extras install nginx1 -y

systemctl enable --now nginx

cd /usr/share/nginx/html

mkdir es/

echo '<h1>hola esta es la version en español</h1>' > es/index.html

#!/bin/bash

# 显示欢迎信息
echo "开始安装Docker和Portainer..."

# 安装Docker
echo "正在安装Docker..."
curl -fsSL https://get.docker.com | bash

# 将当前用户添加到docker组
echo "配置Docker权限..."
sudo usermod -aG docker $USER

# 创建Portainer数据卷
echo "创建Portainer数据卷..."
docker volume create portainer_data

# 安装Portainer
echo "安装Portainer..."
docker run -d -p 8000:8000 -p 9443:9443 --name portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

# 显示结果
echo "==============================================="
echo "✅ 安装完成!"
echo "访问: https://$(curl -s ifconfig.me || hostname -I | awk '{print $1}'):9443"
echo "请创建您的管理员帐户并开始使用Portainer"
echo "==============================================="

# 应用docker组权限(提示用户)
echo "注意: 您可能需要重新登录终端才能使用docker命令而无需sudo"
echo "或者运行: newgrp docker"

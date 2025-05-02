#!/bin/bash

# 检查是否以root权限运行
if [ "$(id -u)" != "0" ]; then
   echo "此脚本必须以root权限运行" 1>&2
   exit 1
fi

# 获取域名
if [ -z "$1" ]; then
    read -p "请输入您的域名 (例如 portainer.yourdomain.com): " domain_name
else
    domain_name=$1
fi

echo "开始配置域名: $domain_name"

# 检测系统类型
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu系统
    echo "检测到Debian/Ubuntu系统"
    
    # 更新软件包列表
    apt update
    
    # 安装Nginx
    echo "安装Nginx..."
    apt install -y nginx
    
    # 安装Certbot
    echo "安装Certbot..."
    apt install -y certbot python3-certbot-nginx
    
    # 配置防火墙
    if command -v ufw &> /dev/null; then
        echo "配置UFW防火墙..."
        ufw allow 80/tcp
        ufw allow 443/tcp
    fi
    
elif [ -f /etc/redhat-release ]; then
    # CentOS/RHEL系统
    echo "检测到CentOS/RHEL系统"
    
    # 安装Nginx
    echo "安装Nginx..."
    yum install -y nginx
    
    # 安装Certbot
    echo "安装Certbot..."
    yum install -y certbot python3-certbot-nginx
    
    # 配置防火墙
    if command -v firewall-cmd &> /dev/null; then
        echo "配置Firewalld防火墙..."
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --reload
    fi
    
else
    echo "不支持的操作系统"
    exit 1
fi

# 启动Nginx
echo "启动Nginx服务..."
systemctl start nginx
systemctl enable nginx

# 创建Nginx配置文件
echo "创建Nginx配置文件..."
cat > /etc/nginx/conf.d/portainer.conf << EOF
server {
    listen 80;
    server_name $domain_name;
    
    location / {
        proxy_pass https://localhost:9443;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

# 测试Nginx配置
echo "测试Nginx配置..."
nginx -t

# 重启Nginx
echo "重启Nginx服务..."
systemctl restart nginx

# 获取SSL证书
echo "开始获取SSL证书..."
echo "请确保您的域名 $domain_name 已正确设置DNS解析并指向此服务器IP"
read -p "按回车键继续获取SSL证书 (Ctrl+C可取消)" -r

certbot --nginx -d $domain_name

echo "==============================================="
echo "✅ 域名配置完成!"
echo "您现在可以通过 https://$domain_name 访问Portainer"
echo "==============================================="

echo "安全提示:"
echo "1. 请使用强密码保护您的Portainer账户"
echo "2. 定期更新系统和应用程序"
echo "3. 考虑设置IP访问限制以提高安全性"

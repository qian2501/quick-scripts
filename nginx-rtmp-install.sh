#!/bin/bash
# Should execute with sudo

# Var
SEP=----------
NGINX_VERSION="nginx-1.18.0"
NGINX_RTMP_MODULE_VERSION="1.2.1"

# Get distro name
OS=$(awk -F'=' '/^ID=/ {print tolower($2)}' /etc/*-release)
# For CentOS the name will contain d-quotes, which need to be removed
OS=${OS#*\"}
OS=${OS%\"*}
# Get package manager from distro
if [ $OS = "ubuntu" ]||[ $OS = "debian" ]; then
    PM=apt
    PKGS="ca-certificates openssl libssl-dev libpcre3-dev"
elif [ $OS = "centos" ]||[ $OS = "rhel" ]; then
    PM=yum
    PKGS="ca-certificates openssl openssl-devel pcre-devel"
fi

echo $SEP
$PM update
$PM install -y $PKGS

# Download and decompress Nginx
echo $SEP
mkdir -p /tmp/build/nginx
cd /tmp/build/nginx
wget -O $NGINX_VERSION.tar.gz https://nginx.org/download/$NGINX_VERSION.tar.gz
tar -xzf $NGINX_VERSION.tar.gz

# Download and decompress RTMP module
echo $SEP
mkdir -p /tmp/build/nginx-rtmp-module
cd /tmp/build/nginx-rtmp-module
wget -O nginx-rtmp-module-$NGINX_RTMP_MODULE_VERSION.tar.gz https://github.com/arut/nginx-rtmp-module/archive/v$NGINX_RTMP_MODULE_VERSION.tar.gz
tar -zxf nginx-rtmp-module-$NGINX_RTMP_MODULE_VERSION.tar.gz

# Build and install Nginx
# The default puts everything under /usr/local/nginx, so it's needed to change explicitly.
# Not just for order but to have it in the PATH
echo $SEP
cd /tmp/build/nginx/$NGINX_VERSION
./configure \
    --sbin-path=/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --pid-path=/var/run/nginx/nginx.pid \
    --lock-path=/var/lock/nginx/nginx.lock \
    --http-log-path=/var/log/nginx/access.log \
    --http-client-body-temp-path=/tmp/nginx-client-body \
    --with-http_ssl_module \
    --with-threads \
    --with-ipv6 \
    --add-module=/tmp/build/nginx-rtmp-module/nginx-rtmp-module-$NGINX_RTMP_MODULE_VERSION
if [ -d /var/lock/nginx ]; then
    mkdir /var/lock/nginx
fi

# Make
echo $SEP
make
make install

# Clean up
echo $SEP
rm -rf /tmp/build

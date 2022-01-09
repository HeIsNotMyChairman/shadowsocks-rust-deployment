# shadowsocks-rust-deployment
A docker based installation for shadowsocks-rust server. Enable v2ray ws, quic, tls.
This is a bash script to deploy shadowsocks-rust on your server. It uses shadowsocks-rust and v2ray as a backend, nginx-proxy as a frontend.
It will install the following dockers
 - [nginxproxy/nginx-proxy](https://github.com/nginx-proxy/nginx-proxy)
 - [nginx-proxy/acme-companion](https://github.com/nginx-proxy/acme-companion)
 - [ghcr.io/shadowsocks/ssserver-rust](https://github.com/shadowsocks/shadowsocks-rust)

# Before installation
Port 80(TCP), 443(TCP/UDP)  and [plain port](https://github.com/HeIsNotMyChairman/shadowsocks-rust-deployment/blob/main/install.sh#L3)(TCP/UDP) on the server is available

The server's IP is assigned with a [domain name](https://github.com/HeIsNotMyChairman/shadowsocks-rust-deployment/blob/main/install.sh#L2)

Install docker using the official installation [documentation](https://docs.docker.com/engine/install/ubuntu/)
# Installation
Set your **domain**, **password**, **port**(only for plain), [**mail**](https://github.com/nginx-proxy/acme-companion/blob/main/README.md#step-2---acme-companion) in [install.sh](https://github.com/HeIsNotMyChairman/shadowsocks-rust-deployment/blob/main/install.sh#L2-L5)

Run install.sh
Here is the example client [configuration file](https://github.com/HeIsNotMyChairman/shadowsocks-rust-deployment/blob/main/client.json)



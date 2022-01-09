#!/bin/sh
domain=your.domain.com
port=10443   # plain port
password=breakwall
mail=acme@your.email.com

sudo docker run -d \
    --name nginx-proxy \
    --publish 80:80 \
    --publish 443:443 \
    --volume certs:/etc/nginx/certs \
    --volume vhost:/etc/nginx/vhost.d \
    --volume html:/usr/share/nginx/html \
    --volume /var/run/docker.sock:/tmp/docker.sock:ro \
    --restart unless-stopped \
    nginxproxy/nginx-proxy

sudo docker run -d \
    --name nginx-proxy-acme \
    --volumes-from nginx-proxy \
    --volume /var/run/docker.sock:/var/run/docker.sock:ro \
    --volume acme:/etc/acme.sh \
    --env "DEFAULT_EMAIL=$mail" \
    --restart unless-stopped \
    nginxproxy/acme-companion

mkdir $HOME/ss-rust-build
cd $HOME/ss-rust-build
wget https://github.com/shadowsocks/shadowsocks-rust/raw/master/Dockerfile.v2ray
sudo docker build -f $HOME/ss-rust-build/Dockerfile.v2ray -t ghcr.io/shadowsocks/ssserver-rust-v2ray .

mkdir $HOME/ss-rust
cat > $HOME/ss-rust/config.json <<EOF
{
    // Server: TCP socket timeout in seconds.
    // Omit this field if you don't have specific needs.
    "timeout": 7200,

    // Extended multiple server configuration
    // SERVER: Creating multiple servers in one process
    "servers": [
        {
            // "disabled": true,
            "server": "0.0.0.0",
            "server_port": $port,
            "method": "chacha20-ietf-poly1305",
            "password": "$password",
        }
    ],

    // Global configurations for UDP associations
    "udp_timeout": 300, // Timeout for UDP associations (in seconds), 5 minutes by default
    "udp_max_associations": 512, // Maximum UDP associations to be kept in one server, unlimited by default

    // Options for Manager
    // "manager_address": "0.0.0.0", // Could be a path to UNIX socket, /tmp/shadowsocks-manager.sock
    // "manager_port": 5300, // Not needed for UNIX socket

    // DNS server's address for resolving domain names
    // For *NIX and Windows, it uses system's configuration by default
    //
    // Value could be IP address of DNS server, for example, "8.8.8.8".
    // DNS client will automatically request port 53 with both TCP and UDP protocol.
    //
    // It also allows some pre-defined well-known public DNS servers:
    // - google (TCP, UDP)
    // - cloudflare (TCP, UDP)
    // - cloudflare_tls (TLS), enable by feature "dns-over-tls"
    // - cloudflare_https (HTTPS), enable by feature "dns-over-https"
    // - quad9 (TCP, UDP)
    // - quad9_tls (TLS), enable by feature "dns-over-tls"
    //
    // The field is only effective if feature "trust-dns" is enabled.
    "dns": "google",

    // Mode, could be one of the
    // - tcp_only
    // - tcp_and_udp
    // - udp_only
    "mode": "tcp_and_udp",

    // TCP_NODELAY
    "no_delay": true,

    // Enables SO_KEEPALIVE and set TCP_KEEPIDLE, TCP_KEEPINTVL to the specified seconds
    "keep_alive": 15,

    // Soft and Hard limit of file descriptors on *NIX systems
    "nofile": 10240,

    // Try to resolve domain name to IPv6 (AAAA) addresses first
    "ipv6_first": false,
    // Set IPV6_V6ONLY for all IPv6 listener sockets
    // Only valid for locals and servers listening on ::
    "ipv6_only": false,

    // Service configurations
    // Logger configuration
    "log": {
        // Equivalent to -v command line option
        "level": 2,
        "format": {
            // Euiqvalent to --log-without-time
            "without_time": false,
        },
        "config_path": "/etc/shadowsocks-rust/config.yaml"
    },
    // Runtime configuration
    "runtime": {
        // single_thread or multi_thread
        "mode": "multi_thread",
        // Worker threads that are used in multi-thread runtime
        "worker_count": 4
    }
}
EOF

cat > $HOME/ss-rust/config.yaml <<EOF
refresh_rate: 30 seconds
appenders:
  stdout:
    kind: console
    encoder:
      pattern: "{d} {h({l}):<5} {m}{n}"
  file:
    kind: rolling_file
    path: /var/log/shadowsocks.log
    encoder:
      kind: pattern
      pattern: "{d} {h({l}):<5} {m}{n}"
    policy:
      trigger:
        kind: size
        limit: 10 mb
      roller:
        kind: fixed_window
        pattern: shadowsocks.{}.log
        count: 5
root:
  level: info
  appenders:
    - stdout
    - file
EOF

sudo docker run -d \
  --name ssserver-rust \
  -v $HOME/ss-rust:/etc/shadowsocks-rust \
  -p $port:$port/udp \
  -p $port:$port \
  --restart unless-stopped \
  ghcr.io/shadowsocks/ssserver-rust-v2ray
  
mkdir $HOME/ss-rust-quic
cat > $HOME/ss-rust-quic/config.json <<EOF
{
    // Server: TCP socket timeout in seconds.
    // Omit this field if you don't have specific needs.
    "timeout": 7200,

    // Extended multiple server configuration
    // SERVER: Creating multiple servers in one process
    "servers": [
        {
            // "disabled": true,
            "server": "0.0.0.0",
            "port": 443,
            "method": "chacha20-ietf-poly1305",
            "password": "$password",
            "plugin": "v2ray-plugin",
            "plugin_opts": "server;mode=quic;cert=/etc/nginx/certs/$domain/fullchain.pem;key=/etc/nginx/certs/$domain/key.pem;loglevel=debug"
        },
        {
            // "disabled": true,
            "server": "0.0.0.0",
            "server_port": 8091,
            "method": "chacha20-ietf-poly1305",
            "password": "$password",
            "plugin": "v2ray-plugin",
            "plugin_opts": "server"
        },
    ],

    // Global configurations for UDP associations
    "udp_timeout": 300, // Timeout for UDP associations (in seconds), 5 minutes by default
    "udp_max_associations": 512, // Maximum UDP associations to be kept in one server, unlimited by default

    // Options for Manager
    // "manager_address": "0.0.0.0", // Could be a path to UNIX socket, /tmp/shadowsocks-manager.sock
    // "manager_port": 5300, // Not needed for UNIX socket

    // DNS server's address for resolving domain names
    // For *NIX and Windows, it uses system's configuration by default
    //
    // Value could be IP address of DNS server, for example, "8.8.8.8".
    // DNS client will automatically request port 53 with both TCP and UDP protocol.
    //
    // It also allows some pre-defined well-known public DNS servers:
    // - google (TCP, UDP)
    // - cloudflare (TCP, UDP)
    // - cloudflare_tls (TLS), enable by feature "dns-over-tls"
    // - cloudflare_https (HTTPS), enable by feature "dns-over-https"
    // - quad9 (TCP, UDP)
    // - quad9_tls (TLS), enable by feature "dns-over-tls"
    //
    // The field is only effective if feature "trust-dns" is enabled.
    "dns": "google",

    // Mode, could be one of the
    // - tcp_only
    // - tcp_and_udp
    // - udp_only
    "mode": "tcp_only",

    // TCP_NODELAY
    "no_delay": true,

    // Enables SO_KEEPALIVE and set TCP_KEEPIDLE, TCP_KEEPINTVL to the specified seconds
    "keep_alive": 15,

    // Soft and Hard limit of file descriptors on *NIX systems
    "nofile": 10240,

    // Try to resolve domain name to IPv6 (AAAA) addresses first
    "ipv6_first": false,
    // Set IPV6_V6ONLY for all IPv6 listener sockets
    // Only valid for locals and servers listening on ::
    "ipv6_only": false,

    // Service configurations
    // Logger configuration
    "log": {
        // Equivalent to -v command line option
        "level": 1,
        "format": {
            // Euiqvalent to --log-without-time
            "without_time": false,
        },
        "config_path": "/etc/shadowsocks-rust/config.yaml"
    },
    // Runtime configuration
    "runtime": {
        // single_thread or multi_thread
        "mode": "multi_thread",
        // Worker threads that are used in multi-thread runtime
        "worker_count": 4
    }
}
EOF

cat > $HOME/ss-rust-quic/config.yaml <<EOF
refresh_rate: 30 seconds
appenders:
  stdout:
    kind: console
    encoder:
      pattern: "{d} {h({l}):<5} {m}{n}"
  file:
    kind: rolling_file
    path: /var/log/shadowsocks.log
    encoder:
      kind: pattern
      pattern: "{d} {h({l}):<5} {m}{n}"
    policy:
      trigger:
        kind: size
        limit: 10 mb
      roller:
        kind: fixed_window
        pattern: shadowsocks.{}.log
        count: 5
root:
  level: debug
  appenders:
    - stdout
    - file
EOF

sudo docker run -d \
  --name ssserver-rust-quic \
  --env "VIRTUAL_HOST=$domain" \
  --env "VIRTUAL_PORT=8091" \
  --env "LETSENCRYPT_HOST=$domain" \
  --env "HTTPS_METHOD=noredirect" \
  -p 443:443/udp \
  -v $HOME/ss-rust-quic:/etc/shadowsocks-rust \
  -v certs:/etc/nginx/certs \
  --restart unless-stopped \
  ghcr.io/shadowsocks/ssserver-rust-v2ray

# Tailscale Derp Server

## How to use

Clone this project and run `docker build . -t tailscale-derp`.

## Description

This derp would also install a tailscale app to enable `verify-clients` function, and this tailscale node **ONLY WORK** for derp.

## Arguments

Those environment variables are required:

* HOST_NAME     - To specific the derp hostname
* CERT_DIR      - To specific the cert storage dir
* TS_AUTHKEY    - The tailscale authkey, generate from `Settings/Personal Settings/Keys/Auth Keys`

## Start your derp service

I do recommend to use `docker-compose`, here is an example:

```yaml
version: "3.3"
services:
  derp:
    image: tailscale-derp:latest
    restart: always
    hostname: derper-server
    container_name: tailscale-derper-1
    logging:
      options:
        max-size: "5m"
    ports:
      - "61443:443"
      - "61443:3478/udp"
    volumes:
      - "/home/ssl:/app/certs" # Mount SSL certificates
      - "derper-tailscale-1:/var/lib/tailscale" # Use named volume for Tailscale data
    environment:
      - TS_AUTHKEY=tskey-auth-xxx
      - TS_STATE_DIR=/var/lib/tailscale
      - DERP_STUN_PORT=3478
      - DERP_VERIFY_CLIENTS=true
      - DERP_DOMAIN=derper-1.poliwhirl.cn
      - DERP_CERT_DIR=/app/certs
      - DERP_CERT_MODE=manual
      - DERP_STUN=true
      - DERP_ADDR=:443
      - DERP_HTTP_PORT=80

volumes:
  derper-tailscale-1: # Define the named volume
```

If you are using nginx to proxy the traffic, map container 443 port to other local port, or use docker network to handle proxy traffic, for example:

```nginx
server {
  listen 80;
  listen [::]:80;
  server_name your_derp_hostname;
  rewrite ^(.*) https://$server_name$1 permanent;
}

server {
  listen 443 ssl;
  listen [::]:443 ssl;

  ssl_certificate       /etc/nginx/conf.d/certs/cert.crt;
  ssl_certificate_key   /etc/nginx/conf.d/certs/cert.key;
  ssl_session_timeout 1d;
  ssl_session_cache shared:MozSSL:10m;
  ssl_session_tickets off;

  ssl_protocols         TLSv1.1 TLSv1.2 TLSv1.3;
  ssl_ciphers           ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
  ssl_prefer_server_ciphers off;

  server_name           your_derp_hostname;
  
  location / {
    proxy_pass https://your_derp_hostname;
    # proxy_ssl_verify on;
    proxy_ssl_server_name on;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Referer https://your_derp_hostname;
    client_max_body_size 200m;
  }
}
```

let Nginx and derp container in the same net, and this would work fine.

<a href="https://github.com/user-attachments/assets/193315b6-0143-4289-bbbd-fdb28540fec4">
  <img align="right" src=".github/cheburnet.png" height="350px"/>
<a>
<i>
Ведь больше нет никого<br>
Ничего-ничего<br>
Смерть подставит плечо<br>
Жизнь выставит счет<br>
И за дверь<br>
Ты уходишь<br>
И вроде бы и не жил<br>
Лишь только снег кружит<br>
</i>
<br clear="right"/>

## (not only) cheburnet

##### ubuntu server init
```sh
IU_SSH_KEY="key" IU_CERT_EMAIL="email" IU_CERT_DOMAIN="domain" bash <(wget -qO- https://raw.githubusercontent.com/vargalott/cheburnet/main/.ubuntu/init.sh)
```

##### check tools
```sh
bash <(wget -qO- ip.check.place) -l en
bash <(wget -qO- check.unlock.media) -E en -R 0
bash <(wget -qO- bench.sh)
bash <(wget -qO- nws.sh)
bash <(wget -qO- https://raw.githubusercontent.com/vernette/censorcheck/master/censorcheck.sh)
bash <(wget -qO- https://raw.githubusercontent.com/vernette/ipregion/master/ipregion.sh)
```

##### misc
```sh
# uuid, PVT+PBK
docker run --rm ghcr.io/xtls/xray-core uuid
docker run --rm ghcr.io/xtls/xray-core x25519
# OR
docker run --rm ghcr.io/sagernet/sing-box:latest generate uuid
docker run --rm ghcr.io/sagernet/sing-box:latest generate reality-keypair

# shortid
openssl rand -hex 8

# certificates
certbot certonly --standalone --agree-tos -m EMAIL -d DOMAIN
certbot renew --dry-run

tr -dc 'A-Za-z0-9' </dev/urandom | head -c 64; echo
rsync -avz --delete -e ssh "server:/root/vaultwarden/data/db_[0-9]*_[0-9]*.sqlite3" $HOME/backups/vaultwarden/
echo "$(tr -dc a-z </dev/urandom | head -c2)$((RANDOM%9+1))--$(tr -dc a-z0-9 </dev/urandom | head -c13)-$( ( [ $((RANDOM%2)) -eq 0 ] && printf '%02d' $((RANDOM%90+10)) ) || echo $(tr -dc a-z </dev/urandom | head -c1)$((RANDOM%9+1)) )"
```

##### flowchat

```mermaid
flowchart TD
  classDef wide padding:100px

  %% Blocks
  CLIENT[Client Device\nScanners\nCensor]:::wide

  TCP443["VLESS-REALITY\n172.20.0.10\nTCP:443"]:::wide
  UDP443["Hysteria2\n172.20.0.15\nUDP:443"]:::wide

  NGINX["Nginx Reverse Proxy\n172.20.0.20"]:::wide
  MASQ["Masquerade Webapp\n172.20.0.30"]:::wide
  CONFIG["Proxy client config\n(mihomo)"]:::wide
  VAULT["Vaultwarden\n172.20.0.40"]:::wide

  TUNNEL["Proxy tunnel"]:::wide
  INTERNET["Internet"]:::wide

  %% Flows
  CLIENT -->|:443/tcp| TCP443
  CLIENT -->|:443/udp| UDP443

  TCP443 -->|auth successful\nvalid shortid/uuid| TUNNEL
  UDP443 -->|auth successful\nvalid userpass| TUNNEL

  TCP443 -->|reality destination\nfailed auth| NGINX
  UDP443 -->|hysteria masquerade\nfailed auth| TCP443

  NGINX -->|https://website/| MASQ
  NGINX -->|https://website/secretpath/config.yaml| CONFIG
  NGINX -->|https://website/vault| VAULT

  TUNNEL --> INTERNET
```

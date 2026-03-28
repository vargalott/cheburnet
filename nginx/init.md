##### init
```
mkdir data && chmod -R 755 ./data
```

##### In case when front listener doesn't support <i>The PROXY protocol</i> ([1](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt), [2](https://docs.nginx.com/nginx/admin-guide/load-balancer/using-proxy-protocol/)) e.g. <i>sing-box</i>, it is necessary to disable its support in <i>nginx/nginx.conf</i> and change the values of <i>X-Real-IP</i>, <i>X-Forwarded-For</i> headers to <i>$remote_addr</i>:
<pre>
listen              443 ssl [default_server] <s><i>proxy_protocol</i></s>;
<s><i>set_real_ip_from    172.20.0.0/24;</i></s>

location /.../ {
    ...
    proxy_set_header    X-Real-IP <s><i>$proxy_protocol_addr</i></s> <i>$remote_addr</i>;
    proxy_set_header    X-Forwarded-For <s><i>$proxy_protocol_addr</i></s> <i>$remote_addr</i>;
    ...
}
</pre>

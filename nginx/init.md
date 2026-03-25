##### init
```
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout ./nginx/dummy.key -out ./nginx/dummy.crt -subj "/CN=invalid.local"
mkdir data && chmod -R 755 ./data
```

##### In case when front listener doesn't support <i>The PROXY protocol</i> ([1](https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt), [2](https://docs.nginx.com/nginx/admin-guide/load-balancer/using-proxy-protocol/)) e.g. <i>sing-box</i>, it is necessary to disable its support in <i>nginx/nginx.conf</i>:
<pre>
listen              443 ssl [default_server] <b><i>proxy_protocol</i></b>;
<b><i>set_real_ip_from    172.20.0.0/24;
real_ip_header      proxy_protocol;</i></b>
</pre>

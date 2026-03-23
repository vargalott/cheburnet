```
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout ./nginx/dummy.key -out ./nginx/dummy.crt -subj "/CN=invalid.local"
mkdir data && chmod -R 755 ./data
```

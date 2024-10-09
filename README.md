# HAProxy backend server switcher

This script uses HAProxy statistics via socket to enable/disable the backend server

Docs — https://docs.haproxy.org/2.4/management.html#9.3

## Preliminary setup

To begin with, install socat on Linux machine as seen below

```
sudo apt install socat
```

Next, open the HAProxy configuration file and add the following lines in the `global` section to enable the stats socket:

```
global
    stats socket /var/run/haproxy.sock mode 600 level admin
    stats timeout 2m
```

Then, save the configuration file and restart the HAProxy service

```
sudo systemctl restart haproxy.service
```

## Using

```shell
bash haproxy-switcher.sh

OR

bash haproxy-switcher.sh "web443/server-1" -socket "/var/run/haproxy_db.sock" -disable
```

## Options

> The order of arguments is *NOT important*

- `-enable` - Enable the backend server
- `-disable` - Enable the backend server
- `-socket` - Path to socket file of HAProxy stats
- `"backend/server"` - Path of "backend/server" for action 
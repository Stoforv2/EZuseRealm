##自用Realm一键安装脚本
####仅安装配置realm基本权限及添加system服务
####测试环境为debian11，其余系统未知

## 使用方法
`wget --no-check-certificate -O realm.sh https://raw.githubusercontent.com/Stoforv2/EZuseRealm/master/realm.sh && chmod +x realm.sh && ./realm.sh`

### 默认安装目录为
`/etc/realm`

### 简单示例配置如下：
```
[log]
level = "warn"
output = "/etc/realm/realm_toml.log"

[dns]
mode = "ipv4_and_ipv6"
protocol = "tcp_and_udp"
nameservers = ["8.8.8.8:53", "8.8.4.4:53"]
min_ttl = 0
max_ttl = 60
cache_size = 256

[network]
no_tcp = false
use_udp = true
zero_copy = true
fast_open = true
tcp_timeout = 300
udp_timeout = 30
send_proxy = false
send_proxy_version = 2
accept_proxy = false
accept_proxy_timeout = 5

[[endpoints]] #中转机TLS示例
listen = "[::]:port" #port为你中转机的入口
remote = "yourdomain1:port1" #domain1:port1为你落地机接收加密数据域名及端口
remote_transport = "tls;sni=yourdomain1" #sni填入你的域名

[[endpoints]] #落地机TLS+证书示例
listen = "[::]:port1" #与中转机的port1保持一致
remote = "[::]:port2" #你转发的目标地址及端口
listen_transport = "tls;cert=/etc/realm/fullchain.crt;key=/etc/realm/private.key" #自定义你证书的目录
remote_transport = ""

[[endpoints]] #tcp+udp不加密转发,直接在中转机实现
listen = "[::]:port"
remote = "yourdomain.com:port"
```

#### [Realm作者](https://github.com/zhboner/realm)

#### 脚本韩[@KANIKIG](https://github.com/KANIKIG/Multi-EasyGost/blob/v2/gost.sh)佬gost脚本改写 

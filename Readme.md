
### Фильтрация трафика - iptables 

#### Задача: 


Что нужно сделать?

1) реализовать knocking port
2) centralRouter может попасть на ssh inetrRouter через knock скрипт пример в материалах.
3) добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост.
4) запустить nginx на centralServer. пробросить 80й порт на inetRouter2 8080.
5) дефолт в инет оставить через inetRouter.



#### Решение


Что ж начнем решать наиши задачи 


Развернем Стенд

```bash
git clone https://github.com/jecka2/iptables.git
cd iptables
vagrant up 
```

После этого у нас развывернется 4 виртуальных машины:

1) inetRouter
2) inetRouter2
3) centralRouter
4) centralServer


1) Реализация port noking описана в  templates/iptables_rules.ipv4

```bash
-A INPUT -j TRAFFIC
-A TRAFFIC -m state --state ESTABLISHED,RELATED -j ACCEPT
-A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 22 -m recent --rcheck --seconds 30 --name SSH2 -j ACCEPT
-A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH2 --remove -j DROP
-A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 9991 -m recent --rcheck --name SSH1 -j SSH-INPUTTWO
-A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH1 --remove -j DROP
-A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 7777 -m recent --rcheck --name SSH0 -j SSH-INPUT
-A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH0 --remove -j DROP
-A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 8881 -m recent --name SSH0 --set -j DROP
-A SSH-INPUT -m recent --name SSH1 --set -j DROP
-A SSH-INPUTTWO -m recent --name SSH2 --set -j DROP
-A TRAFFIC -j DROP

```
Что говорти нам о том , что наш сервре ожидает подключения сначало на 8881 затем  на 7777  и потом 9991 после чего откроет нам 22 порт для ssh


2) Скрипт для Port Knocking  - iptables/knock.sh загружается на сервер centralRouter

```bash
#!/bin/bash
HOST=$
shift
for ARG in "$@"
do
        sudo nmap -Pn --max-retries 0 -p $ARG $HOST
done
```


для подключения необходимо указать следующее bash ./knock.sj 192.168.251 8881 7777 9991 после этого нащ сервер будет готов принмать соединения на 22 порт для подключения

3) Добавлен сервер  inetRouter2


 :inetRouter2 => {
        :box_name => "generic/ubuntu2204",
        :vm_name => "inetRouter2",
        #:public => {:ip => "10.10.10.1", :adapter => 1},
        :net => [   
                    #ip, adpter, netmask, virtualbox__intnet
                    ["192.168.255.3", 2, "255.255.255.248",  "router-net"], 
                    ["192.168.50.11", 8, "255.255.255.0"],

4) Создан нат на inetRouter2  для переброски с порта 8080 на сервер centralServer на порт 80  

-A PREROUTING -i eth1 -p tcp -m tcp --dport 8080 -j DNAT --to-destination 192.168.0.2:80
-A POSTROUTING -d 192.168.0.2/32 -p tcp -m tcp --dport 80 -j SNAT --to-source 192.168.0.2:80



5) Дефолт в инет оставить через inetRouter.


 routes:
      - to: 0.0.0.0/0
        via: 192.168.255.1


```bash
docker exec openvpn-entreprise5 sysctl -w net.ipv4.ip_forward=1
docker exec openvpn-entreprise5 iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE

# Allow BGP updates without strict policies on both border routers
docker exec as5-border vtysh -c "conf t" -c "router bgp 5" -c "no bgp ebgp-requires-policy"
docker exec internet-router vtysh -c "conf t" -c "router bgp 1" -c "no bgp ebgp-requires-policy"

# Teach Internet Router how to reach the Secondary Site LAN (Static Route)
docker exec internet-router ip route add 10.0.2.0/24 via 10.0.1.10

# Force BGP to refresh immediately
docker exec as5-border vtysh -c "clear ip bgp * soft"

docker exec -it as5-border vtysh -c "show ip ospf neighbor"

docker exec -it as5-border vtysh -c "show ip bgp summary"

docker exec -it as5-border vtysh -c "show ip bgp"

docker exec -it client-entreprise5-1 sh

nslookup www.entreprise5.lan 120.0.84.10

nslookup google.com 120.0.85.10

curl -I [http://nginx-entreprise5.entreprise5.lan](http://nginx-entreprise5.entreprise5.lan)

# Exit client first if radtest is missing
exit 

# Run test on Radius Server
docker exec radius-entreprise5 radtest user1 password1 127.0.0.1 0 testing123

docker exec asterisk-entreprise5 asterisk -rx "pjsip show endpoints"

docker exec openvpn-site-secondaire sh -c "openvpn --config /etc/openvpn/client-entreprise.conf --dev tun1 --daemon"

docker exec openvpn-site-secondaire ip addr show tun1

docker exec openvpn-site-secondaire wget -qO- [http://120.0.84.13](http://120.0.84.13)



#pour tester mon OSPF + BGP 

docker exec -it as5-border vtysh

show ip ospf neighbor
show ip route ospf
show ip bgp summary
show ip bgp
show ip bgp neighbors 120.0.81.2 advertised-routes
docker exec as5-internal ping -c 2 10.0.0.1
docker exec client-entreprise5-1 ping -c 2 120.0.80.1
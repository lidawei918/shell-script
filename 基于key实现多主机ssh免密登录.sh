#!/bin/bash
PASSWORD=123456
END=254
IP=`ip a show ens33 |awk -F"[ /]+" 'NR==3{print $3}'`
NET=${IP%.*}.

# 扫描同网段所有主机，并加入列表
rm -rf /root/.ssh/id_rsa
[ -e ./SCANIP.LOG ] && rm -rf SCANIP.LOG
for ((i=3;i<="$END";i++));do
  ping -c 1 -w 1 ${NET}$i &> /dev/null && echo "${NET}$i" >> SCANIP.LOG &
done
wait

# 生成密钥，复制到自己的.ssh
ssh-keygen -P "" -f /root/.ssh/id_rsa
rpm -q sshpass &> /dev/null || yum install -y sshpass
sshpass -p $PASSWORD ssh-copy-id -o StrictHostKeyChecking=no $IP

# 复制密钥给其他主机
AliveIP=(`cat SCANIP.LOG`)
for n in ${AliveIP[*]};do
sshpass -p $PASSWORD scp -o StrictHostKeyChecking=no -r /root/.ssh root@${n}:
done

# 复制信任主机列表到其他被控主机
for n in ${AliveIP[*]};do
scp /root/.ssh/known_hosts ${n}:.ssh/
done

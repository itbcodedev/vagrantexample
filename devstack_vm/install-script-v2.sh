# Devstack post script
#   sawangpong muadphet <sawangpong@itbakery.net>
#   version 0.2    11 April 2020
#   minimum devstack local.conf 
# update & install dependency

sudo yum groupinstall 'Development Tools' -y
sudo yum install gcc openssl-devel bzip2-devel libffi libffi-devel -y 
sudo yum update -y
sudo yum install wget git vim tmux -y
sudo yum install bridge-utils -y
sudo yum install epel-release -y
sudo yum install python36  python36-pip -y
sudo systemctl stop firewalld
sudo pip3 install -U  pip
sudo pip3 install -U  virtualenv
sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
sudo echo "
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
"  >>  /etc/sysctl.conf 
sudo sysctl -p
sudo setenforce 0
sudo sestatus


# set hostname & /etc/hosts
sudo hostnamectl set-hostname devstack
ip_address=$(ip addr show eth0 | grep -w inet | awk '{ sub("/.*", "", $2); print $2 }')
host_name=$(hostname -s)
echo  "$ip_address $host_name" >> /etc/hosts

sudo useradd -s /bin/bash -d /opt/stack -m stack
echo 'stack ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/stack

# fix Rabbitmq
#sudo mkdir /etc/rabbitmq
#sudo touch /etc/rabbitmq/rabbitmq-env.conf 
#echo 'NODENAME=rabbit@devstack' | sudo tee /etc/rabbitmq/rabbitmq-env.conf 

# clean
sudo su - stack -c 'rm -rf ~/.ssh'
sudo su - stack -c 'rm -rf ~/stack'
# sudo su - stack mean run as stack user
sudo su - stack -c 'mkdir ~/.ssh && touch ~/.ssh/known_hosts && chmod 600 ~/.ssh/*'
sudo su - stack -c 'ssh-keyscan -H openstack.org >> ~/.ssh/known_hosts'
sudo su - stack -c 'echo  ~/.ssh/known_hosts'
sudo su - stack -c 'git clone https://git.openstack.org/openstack-dev/devstack'

#create local.conf
sudo su - stack -c "
echo '
[[local|localrc]]
ADMIN_PASSWORD=secrete
DATABASE_PASSWORD=\$ADMIN_PASSWORD
RABBIT_PASSWORD=\$ADMIN_PASSWORD
SERVICE_PASSWORD=\$ADMIN_PASSWORD
SKIP_PATH_SANITY=1
GIT_BASE=\${GIT_BASE:-https://opendev.org}
HOST_IP=$ip_address
#FLOATING_RANGE=10.0.2.25/28
RECLONE=yes
FORCE=yes
USE_PYTHON3=True
PYTHON_VERSION=3.6


'  > /opt/stack/devstack/local.conf
"

sudo su - stack -c "sudo chown -R stack:stack /opt/stack"
sudo su - stack -c "sudo chmod -R 755 /opt/stack"



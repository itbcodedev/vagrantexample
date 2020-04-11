# Devstack post script
#   sawangpong muadphet <sawangpong@itbakery.net>
#   version 0.2    11 April 2020
#   Customize devstack local.conf 
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
RECLONE=yes
FORCE=yes
USE_PYTHON3=True
PYTHON_VERSION=3.6


# Enable neutron
disable_service n-net
enable_service q-svc
enable_service q-agt
enable_service q-dhcp
enable_service q-l3
enable_service q-meta

# Enable services ceilometer
enable_plugin ceilometer \${GIT_BASE}/openstack/ceilometer master
enable_service ceilometer-acompute
enable_service ceilometer-acentral
enable_service ceilometer-collector
enable_service ceilometer-alarm-singleton
enable_service ceilometer-alarm-notifier
enable_service ceilometer-alarm-evaluator
enable_service ceilometer-api


# Enable service heat
enable_plugin heat  \${GIT_BASE}/openstack/heat master
enable_service h-eng 
enable_service h-api 
enable_service h-api-cfn 
enable_service h-api-cw



## Neutron options
Q_USE_SECGROUP=True
FLOATING_RANGE="10.0.2.0/24"
IPV4_ADDRS_SAFE_TO_USE="10.0.2.0/22"
Q_FLOATING_ALLOCATION_POOL=start=10.0.2.250,end=10.0.2.254
PUBLIC_NETWORK_GATEWAY="10.0.2.2"
PUBLIC_INTERFACE=eth0

## Open vSwitch provider networking configuration
Q_USE_PROVIDERNET_FOR_PUBLIC=True
OVS_PHYSICAL_BRIDGE=br-ex
PUBLIC_BRIDGE=br-ex
OVS_BRIDGE_MAPPINGS=public:br-ex

enable_service tempest

'  > /opt/stack/devstack/local.conf
"

sudo su - stack -c "sudo chown -R stack:stack /opt/stack"
sudo su - stack -c "sudo chmod -R 755 /opt/stack"



#!/bin/bash  
 
# 
# script to setup new machine 
# 
# install git, docker
# 
 
# assuming ec2 user ubuntu,  
SUSER=ubuntu 
 
[ -z "$USER" ] && USER=`whoami` 
 
# if user is not ubuntu (and not root) then change user name to current user 
if [ $USER != $SUSER -a $USER != "root" ]; then 
    echo "adjusting username to $USER" 
    SUSER=$USER 
fi 
 
SHOME=/home/$SUSER 
 
# Install pre-reqs  
sudo apt-get update -y  
sudo apt-get install -y git 
  
# install docker 
dpkg -s docker-ce &> /dev/null 
 
if [ $? -eq 0 ]; then 
    echo "Docker already installed!" 
else 
    curl -fsSL test.docker.com -o get-docker.sh && sh get-docker.sh 
    sudo usermod -aG docker $SUSER 
fi 
 
# enable password login
sudo sed -i '/PasswordAuthentication no/c\PasswordAuthentication yes' /etc/ssh/sshd_config
 
sudo service ssh restart 
 
# change pw 
PW=ArmDocker2019
echo "ubuntu:$PW" | sudo chpasswd 
 
# don't reset password when an AMI is made
sudo sed -i '/lock_passwd: True/c\     lock_passwd: False' /etc/cloud/cloud.cfg 

# Add experimental features to $HOME/.bashrc (if not already there) 
if grep -q "DOCKER_CLI_EXPERIMENTAL" $HOME/.bashrc; then 
    echo "experimental features already set in .bashrc" 
else 
    echo "export DOCKER_CLI_EXPERIMENTAL=enabled" >> $HOME/.bashrc
fi
 
# enable remote docker daemon
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo touch /etc/systemd/system/docker.service.d/options.conf

echo "[Service]" | sudo tee -a /etc/systemd/system/docker.service.d/options.conf
echo "ExecStart=" | sudo tee -a /etc/systemd/system/docker.service.d/options.conf
echo "ExecStart=/usr/bin/dockerd -H unix:// -H tcp://0.0.0.0:2375" | sudo tee -a /etc/systemd/system/docker.service.d/options.conf

# enable experimental features on docker daemon
echo "{" | sudo tee -a /etc/docker/daemon.json 
echo "    \"experimental\": true" | sudo tee -a /etc/docker/daemon.json 
echo "}" | sudo tee -a /etc/docker/daemon.json 

# Reload the systemd daemon.
sudo systemctl daemon-reload

# Restart Docker.
sudo systemctl restart docker


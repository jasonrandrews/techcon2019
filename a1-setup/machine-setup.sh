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
echo -e "ArmDocker2019\nArmDocker2019\n" | sudo passwd ubuntu 
 
# Add experimental features to $HOME/.bashrc (if not already there) 
if grep -q "DOCKER_CLI_EXPERIMENTAL" $HOME/.bashrc; then 
    echo "experimental features already set in .bashrc" 
else 
    echo "export DOCKER_CLI_EXPERIMENTAL=enabled" >> $HOME/.bashrc
fi
 

#!/bin/bash -x
sudo yum update -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y

## Install Java 11:
sudo yum install java-11* -y

## Install Jenkins then Enable the Jenkins service to start at boot :
sudo yum install jenkins -y
sudo systemctl enable jenkins

## Start Jenkins as a service:
sudo systemctl start jenkins
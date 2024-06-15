You have recently joined the company as a DevOps Engineer. Upon your arrival, you discovered that each time a Jenkins server is needed, they must create it manually and use a bash shell script to provision it. Since the company is migrating to the cloud, your task is to write a terraform code that will automate the creation of the Jenkins server and provision it.

Below is what is expected of you at the end of this period:


- Propose a solution using infrastructure as code (Terraform), which allows you to use the script below to configure a Jenkins server in AWS.


- We remind you that the Jenkins server must be attached to a security group that opens port 8080.


- To enable your collaborators to work on the same code as you, set up a remote backend of your terraform code with an S3 Bucket.


- Using DynamoDB, configure a “lock state” in this infrastructure, to prevent the state file from being corrupted when more than one collaborator executes the Terraform Apply command at the same time.
 

Bash Script for the server installation :
```
#!/bin/bash -x
sudo yum update -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y

#Install Java 11:
sudo yum install java-11* -y

#Install Jenkins then Enable the Jenkins service to start at boot :
sudo yum install jenkins -y
sudo systemctl enable jenkins

#Start Jenkins as a service:
sudo systemctl start jenkins

````

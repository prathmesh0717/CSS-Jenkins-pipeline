# Integrated DevOps Tools & Created Pipeline 
### GitHub-Docker-Kubernetes-Jenkins
Creating an integrated DevOps pipeline involving GitHub, Docker, Kubernetes, and Jenkins is a powerful way to manage and deploy CSS templates (or any other type of application). 
### Here's a high-level overview of how you can set up such a pipeline:
## Download CSS-TEMPLATE Files
###### (index.html,CSS,images,JS)
```shell
curl -O https://www.free-css.com/assets/files/free-css-templates/download/page296/healet.zip
```
#### *Upload all above CSS-Template files to github Repository

## Create Dockerfile & upload to same Repository
```shell
vim Dockerfile
```
```shell
FROM nginx:latest
COPY . /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## Create Jenkins Server(java-17-openjdk):AWS_INSTANCE 
###### Use Ubuntu Image(AMI)
### Connect jenkins(Instance) server & use its Terminal
###### INSTALL JAVA PACK
```shell
sudo apt update
sudo apt install fontconfig openjdk-17-jre
sudo java -version
sudo update-alternatives --config java   #update java version to openjdk version "17.0.8" 2023-07-18
```
```
sudo java -version
# openjdk version "17.0.8" 2023-07-18
# OpenJDK Runtime Environment (build 17.0.8+7-Debian-1deb12u1)
# OpenJDK 64-Bit Server VM (build 17.0.8+7-Debian-1deb12u1, mixed mode, sharing)
```
###### INSTALL Jenkins
```shell
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
```
```
sudo apt-get install jenkins -y
```
```shell
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins
```
```
sudo systemctl status jenkins
```
###### initialAdminPassword
```shell
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
## Now, Hit PublicIP(jenkin_Instance):8080 on Browser to start Jenkins-server
###### PASSWORD >>> cat /var/lib/jenkins/secrets/initialAdminPassword
###  Install suggested plugins & Add Plugins
##### 1.Git
##### 2.Docker
##### 3.Kubernetes
##### 4.Stage-view
##### 5.Aws-Credential
### Add Credentials
##### 1.Docker-creds(USERNAME & TOKEN/PASSWORD)
##### 2.AWS-creds(ACCESS_KEY & SECRETE_KEY)

## Use jenkins_Instance Terminal
###### Install required packages:
```shell
sudo apt-get install docker.io -y
sudo apt-get install git -y
```
```
sudo systemctl start docker
sudo systemctl enable docker
```
```shell
sudo chmod 666 /var/run/docker.sock
#sudo gpasswd -aG jenkins docker
sudo gpasswd -a jenkins docker
sudo chown jenkins /var/run/docker.sock
```
```shell
sudo -i
```
```
ll /var/run/docker.sock
```
## Set-Up Kubernetes on Jenkins server
### Create cluster and node(EKS Service)
#### Paste below commands on jenkins server to configure kubernetes
```shell
sudo -i
```
```
snap install aws-cli --classic
```
```
aws configure
```
```
aws eks update-kubeconfig --region ap-south-1 --name my-cluster
```
```shell
aws eks update-kubeconfig --region ap-south-1 --name my-cluster --kubeconfig /tmp/config        #ap-south-1(Region_of_Cluster) & my-cluster(cluster_Name)
```
```
chown jenkins:jenkins /tmp/config
```
### Install kubectl commands on jenkins server
```shell
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
sudo chmod +x kubectl
      mkdir -p ~/.local/bin
      mv ./kubectl ~/.local/bin/kubectl
      # and then append (or prepend) ~/.local/bin to $PATH
```
```shell
sudo kubectl cluster-info
```
## Create Manifest-file/yaml-file & upload to Github repository
```shell
vim k8s-pipeline.yml
```
```shell
apiVersion: apps/v1
kind: Deployment
metadata:
  name: css-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      name: pipeline-tag
  template:
    metadata:
      name: my-css
      labels:
        name: pipeline-tag
    spec: 
      containers:
      - name: docker-jenkins
        image: prathmesh72/css      #DockerHub_Image
        ports:
        - containerPort: 80
          protocol: TCP
---
apiVersion: v1
kind: Service
metadata:
  name: css-service
spec:
  selector:
    name: pipeline-tag      #This tag should match the labels in the deployment
  ports:
  - name: http
    targetPort: 80
    port: 80
    protocol: TCP
  type: LoadBalancer
```
#
## Create devops-tool-pipeline(jenkinsfile) & upload to Github repository
```shell
vim devops-tool-pipeline
```
```shell
pipeline {
    agent any

    stages {
        stage('code-check') {
            steps {
               git branch: 'main', url: 'https://github.com/prathmeshkaral/CSS-Jenkins-pipeline.git'
            }
        }
        stage('Docker-build') {
            steps {
                sh 'docker build -t prathmesh72/css:${BUILD_NUMBER} .'
            }
        }
        stage('docker-push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-cred', passwordVariable: 'passwd', usernameVariable: 'uname')]) {
                    sh "docker login -u ${env.uname} -p ${env.passwd}"
                    sh 'docker push  prathmesh72/css:${BUILD_NUMBER}'
                }
            }
        }
        stage('kubernetes-deploy') {
            steps {
                withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'aws-cred', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    script {
                        sh """
                    aws eks update-kubeconfig --name eks --region us-east-1 --kubeconfig /tmp/config
                    kubectl apply -f k8s-pipeline.yml  --kubeconfig=/tmp/config
                    kubectl set image deployment/css-deployment docker-jenkins=prathmesh72/css:${BUILD_NUMBER}  --kubeconfig=/tmp/config
                    """
                    }
                }
            }
        }
    }
}
```
### Last stage of pipeline explained here:
#### stage('Deploy to Kubernetes') > script {sh""" -//- """}
######  Mention your Cluster_Name at my-cluster & Region at ap-south-1
#### aws eks update-kubeconfig --name my-cluster --region ap-south-1 --kubeconfig /tmp/config
#
###### Mention your YAML_file name at k8s-pipeline.yml
#### kubectl apply -f k8s-pipeline.yml  --kubeconfig=/tmp/config
#
###### kubectl set image deployment/<Deployment_Name> <Container_Name>=<DockerHub_Repository>:${env.BUILD_NUMBER}  --kubeconfig=/tmp/config
#### kubectl set image deployment/css-deployment docker-jenkins=sohampatil08/devops-tool-jenkins-pipeline:${env.BUILD_NUMBER}  --kubeconfig=/tmp/config
This command updates the docker-jenkins container image in the <css-deployment> deployment to a specific version of the <sohampatil08/devops-tool-jenkins-pipeline> image, determined by the build number from a CI/CD pipeline, using a specific kubeconfig file to connect to the cluster.
#
## Create Job on jenkins server (GUI)
#### Create, New item > Pipeline > pipeline script from SCM(Advanced Project Options) 
##### Git_Repository_URL (mention branch) > Script Path:Github_pipeline_file:<devops-tool-pipeline(jenkinsfile)
###### SAVE & APPLY
### After successfully uploaded all the files on GitHub Repository, and created job/item on jenkins GUI, 
#### Hit the > Build Now
## You will get result of Build stages:
![Build stage Result](result-images/build-stages.png)
#
## Get the DNS of LoadBalancer from jenkins Terminal/EC2(LoadBalancer):
![COPY DNS of LB](result-images/LoadBalancer-DNS.png)
#
## Hit the DNS on Browser to watch Deployed Application:
![Final Result of Deployed CSS Template](result-images/DevOps-pipeline-result.png)
#### THANK YOU

````
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
````

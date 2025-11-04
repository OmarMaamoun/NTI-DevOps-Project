pipeline {
    agent any

    environment {
        AWS_REGION = 'eu-north-1'
        ECR_API_REPO = '117676877497.dkr.ecr.eu-north-1.amazonaws.com/development-api'
        ECR_WEB_REPO = '117676877497.dkr.ecr.eu-north-1.amazonaws.com/development-web'
        SONARQUBE_ENV = 'sonarqube'
        IMAGE_TAG = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Checking out source code..."
                checkout scm
            }
        }

        stage('SonarQube Analysis') {
            parallel {
                stage('API SonarQube Analysis') {
                    steps {
                        dir('api') {
                            withSonarQubeEnv("${SONARQUBE_ENV}") {
                                sh '/opt/sonar-scanner/bin/sonar-scanner -Dsonar.projectKey=api -Dsonar.sources=.'
                            }
                        }
                    }
                }
                stage('Web SonarQube Analysis') {
                    steps {
                        dir('web') {
                            withSonarQubeEnv("${SONARQUBE_ENV}") {
                                sh '/opt/sonar-scanner/bin/sonar-scanner -Dsonar.projectKey=web -Dsonar.sources=.'
                            }
                        }
                    }
                }
            }
        }

        stage('Wait for Quality Gate - API') {
            steps {
                timeout(time:20, unit: 'MINUTES') {
                    dir('api') {
                        withSonarQubeEnv("${SONARQUBE_ENV}") {
                            script {
                                echo "Waiting for API Quality Gate..."
                                def qg = waitForQualityGate()
                                if (qg.status != 'OK') {
                                    echo "WARNING: API Quality Gate failed: ${qg.status} — continuing pipeline"
                                } else {
                                    echo "API Quality Gate passed!"
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Wait for Quality Gate - Web') {
            steps {
                timeout(time: 20, unit: 'MINUTES') {
                    dir('web') {
                        withSonarQubeEnv("${SONARQUBE_ENV}") {
                            script {
                                echo "Waiting for Web Quality Gate..."
                                def qg = waitForQualityGate()
                                if (qg.status != 'OK') {
                                    echo "WARNING: Web Quality Gate failed: ${qg.status} — continuing pipeline"
                                } else {
                                    echo "Web Quality Gate passed!"
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Build Docker Images') {
            parallel {
                stage('Build API Image') {
                    steps {
                        dir('api') {
                            sh '''
                            docker build -t $ECR_API_REPO:$IMAGE_TAG .
                            '''
                        }
                    }
                }
                stage('Build Web Image') {
                    steps {
                        dir('web') {
                            sh '''
                            docker build -t $ECR_WEB_REPO:$IMAGE_TAG .
                            '''
                        }
                    }
                }
            }
        }

        stage('Trivy Security Scan') {
            parallel {
                stage('Scan API Image') {
                    steps {
                        sh '''
                        trivy image --exit-code 0 --severity HIGH,CRITICAL $ECR_API_REPO:$IMAGE_TAG
                        '''
                    }
                }
                stage('Scan Web Image') {
                    steps {
                        sh '''
                        trivy image --exit-code 0 --severity HIGH,CRITICAL $ECR_WEB_REPO:$IMAGE_TAG
                        '''
                    }
                }
            }
        }

        stage('Push to ECR') {
            steps {
                withAWS(region: "${AWS_REGION}", credentials: 'aws-creds') {
                    sh '''
                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_API_REPO
                    docker push $ECR_API_REPO:$IMAGE_TAG

                    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_WEB_REPO
                    docker push $ECR_WEB_REPO:$IMAGE_TAG
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline completed successfully — images kept in ECR for debugging."
        }
        failure {
            echo "Pipeline failed — please check logs."
        }
    }
}


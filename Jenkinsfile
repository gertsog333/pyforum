// =============================================================================
// Jenkinsfile — PyForum CI/CD Pipeline (AWS Stage)
//
// Pipeline stages:
//   1. Checkout  — git checkout
//   2. Test      — Django tests with SQLite (no DB needed)
//   3. Deploy    — SSH to app EC2, git pull, docker compose up
//
// Prerequisites in Jenkins:
//   - Credential 'pyforum-deploy-key': SSH private key for ec2-user on app EC2
//   - Parameter APP_EC2_IP: Elastic IP of app EC2 (set after terraform apply)
// =============================================================================

pipeline {
    agent { label 'pyforum-agent' }

    triggers { pollSCM('H/2 * * * *') }

    parameters {
        string(
            name: 'APP_EC2_IP',
            defaultValue: '',
            description: 'Elastic IP of the app EC2 instance (set after terraform apply)'
        )
    }

    environment {
        DEPLOY_USER = 'ec2-user'
        DEPLOY_DIR  = '/home/ec2-user/pyforum/docker'
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Test') {
            steps {
                sh '''
                    pip3 install --no-cache-dir --break-system-packages -r requirements-test.txt
                    python3 manage.py test \
                        --settings=forum-sandbox.test_settings \
                        --verbosity=2
                '''
            }
        }

        stage('Deploy') {
            when {
                expression { return params.APP_EC2_IP?.trim() != '' }
            }
            steps {
                sshagent(credentials: ['pyforum-deploy-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no \\
                            ${DEPLOY_USER}@${params.APP_EC2_IP} \\
                            "cd ${DEPLOY_DIR} && git pull && docker compose --env-file .env.aws -f docker-compose.aws.yml up --build -d"
                    """
                }
            }
        }
    }

    post {
        success { echo "Pipeline SUCCESS — branch: ${env.BRANCH_NAME ?: 'main'}" }
        failure { echo "Pipeline FAILED — branch: ${env.BRANCH_NAME ?: 'main'}" }
    }
}

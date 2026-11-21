pipeline {
    agent any

    triggers {
        pollSCM('H/2 * * * *')
        githubPush()
    }

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Build') {
            steps {
                script { run("docker build -t myapp:${env.BUILD_NUMBER} .") }
            }
        }

        stage('Test') {
            steps {
                script { run("docker run --rm myapp:${env.BUILD_NUMBER} php -l /var/www/html/index.php") }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    if (isUnix()) {
                        env.PREV_IMAGE = sh(script: "docker inspect --format='{{.Config.Image}}' myapp 2>/dev/null || true", returnStdout: true).trim()
                        echo "Currently running: ${env.PREV_IMAGE ?: 'nothing'}"
                    }
                    runIgnoreErrors("docker rm -f myapp")
                    run("docker run -d --restart unless-stopped --name myapp -p 8081:80 -e BUILD=${env.BUILD_NUMBER} myapp:${env.BUILD_NUMBER}")
                }
            }
        }

        stage('Smoke test') {
            steps {
                sleep 5
                script { run("curl -fs http://localhost:8081 | grep 'Build: ${env.BUILD_NUMBER}'") }
            }
        }
    }

    post {
        success { echo "Build ${env.BUILD_NUMBER} deployed successfully" }
        failure {
            script {
                if (isUnix() && env.PREV_IMAGE) {
                    def prevBuild = env.PREV_IMAGE.tokenize(':')[1]
                    echo "Deploy failed, rolling back to ${env.PREV_IMAGE}"
                    sh "docker rm -f myapp || true"
                    sh "docker run -d --restart unless-stopped --name myapp -p 8081:80 -e BUILD=${prevBuild} ${env.PREV_IMAGE}"
                } else {
                    echo "Build ${env.BUILD_NUMBER} failed before deploy, old version is still running"
                }
            }
        }
    }
}

def run(String cmd) {
    if (isUnix()) { sh cmd } else { bat cmd }
}

def runIgnoreErrors(String cmd) {
    if (isUnix()) { sh(script: cmd, returnStatus: true) } else { bat(script: cmd, returnStatus: true) }
}

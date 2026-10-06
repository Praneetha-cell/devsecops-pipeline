// Alternative to GitHub Actions: same gates, Jenkins declarative pipeline.
pipeline {
  agent any
  environment {
    ECR_REPO  = credentials('ecr-repo-uri')   // e.g. 123456789012.dkr.ecr.ap-south-1.amazonaws.com/devsecops-app
    IMAGE_TAG = "${env.GIT_COMMIT}"
  }
  stages {
    stage('Unit Tests') {
      steps {
        sh 'python3 -m venv .venv && . .venv/bin/activate && pip install -r requirements-dev.txt && pytest'
      }
    }
    stage('Code Quality (SonarQube)') {
      steps {
        withSonarQubeEnv('sonarqube') { sh 'sonar-scanner' }
        timeout(time: 5, unit: 'MINUTES') { waitForQualityGate abortPipeline: true }
      }
    }
    stage('Dependency / Secret Scan') {
      steps { sh 'trivy fs --scanners vuln,secret,misconfig --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 .' }
    }
    stage('Build Image') {
      steps { sh 'docker build -t app:${IMAGE_TAG} .' }
    }
    stage('Container Scan / Security Gate') {
      steps { sh 'trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 app:${IMAGE_TAG}' }
    }
    stage('Push + Deploy') {
      when { branch 'main' }
      steps {
        sh '''
          docker tag app:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
          docker push ${ECR_REPO}:${IMAGE_TAG}
          sed "s|IMAGE_PLACEHOLDER|${ECR_REPO}:${IMAGE_TAG}|" k8s/deployment.yaml | kubectl apply -f -
          kubectl -n devsecops rollout status deployment/devsecops-app --timeout=180s
        '''
      }
    }
  }
}

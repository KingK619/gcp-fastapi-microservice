pipeline {
    agent any

    environment {
        // Dynamically tag images with the short Git SHA for traceability
        IMAGE_TAG = "${env.GIT_COMMIT[0..7]}"
        
        // Define your GCP specific variables here
        // IMPORTANT: Replace 'project-f37a4860-d512-457a-b73' with your actual GCP_PROJECT_ID
        GCP_PROJECT_ID = "project-f37a4860-d512-457a-b73"
        REGION = "southamerica-west1"
        REPO_NAME = "devsecops-docker-repo"
        APP_NAME = "fast-api-microservice"
        
        // Construct the full GAR image path
        GAR_IMAGE_PATH = "${REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${REPO_NAME}/${APP_NAME}"
    }

    stages {
        stage('Checkout') {
            steps {
                echo "1. Pulling latest code from GitHub..."
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "2. Building Docker Image: ${GAR_IMAGE_PATH}:${IMAGE_TAG}"
                sh "docker build -t ${GAR_IMAGE_PATH}:${IMAGE_TAG} ."
            }
        }

      stage('Push to Google Artifact Registry') {
            steps {
                echo "3. Pushing artifact to Google Cloud..."
                sh '''
                    # Fetch the token using 'cut' to completely bypass Jenkins regex parsing bugs
                    TOKEN=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" -H "Metadata-Flavor: Google" | cut -d'"' -f4)
                    
                    # Safety check
                    if [ -z "$TOKEN" ]; then
                        echo "ERROR: Token is empty! Metadata server failed."
                        exit 1
                    fi
                    
                    # Log into Artifact Registry (no https:// prefix needed)
                    docker login -u oauth2accesstoken -p "$TOKEN" ${REGION}-docker.pkg.dev
                    
                    # Push the image
                    docker push ${GAR_IMAGE_PATH}:${IMAGE_TAG}
                '''
            }
        }
        
        stage('Deploy Notification') {
            steps {
                echo "Pipeline Complete! The artifact ${IMAGE_TAG} is ready in Artifact Registry."
            }
        }
    }
}
import os
from fastapi import FastAPI

app = FastAPI(title="GCP GitOps Microservice")

@app.get("/")
def read_root():
    # Attempt to read the secret injected by Vault from the environment
    db_pass = os.getenv("DB_PASSWORD", "No Secret Injected Yet")
    
    return {
        "status": "online",
        "environment": "production",
        "region": "southamerica-west1",
        "vault_secret_status": "authenticated" if db_pass != "No Secret Injected Yet" else "pending",
        "message": "Hello from the pure GCP GitOps Pipeline! Version 1.0"
    }
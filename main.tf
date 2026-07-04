# ---------------------------------------------------------
# 1. PROVIDER CONFIGURATION
# ---------------------------------------------------------
provider "google" {
  project = "project-f37a4860-d512-457a-b73"
  region  = "southamerica-west1"
  zone    = "southamerica-west1-a"
}

# ---------------------------------------------------------
# 2. THE MANAGEMENT PLANE: JENKINS MASTER VM (Free Tier)
# ---------------------------------------------------------
resource "google_compute_instance" "jenkins_master" {
  name         = "jenkins-master-vm"
  machine_type = "e2-micro"      # The strictly Free-Tier eligible VM
  zone         = "southamerica-west1-a" # Must be a free-tier eligible zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 30 # 30 GB standard persistent disk is free
    }
  }

  network_interface {
    network = "default"
    access_config {
      # This block gives the VM a public IP so we can access the Jenkins UI
    }
  }

  tags = ["jenkins-server"]
}

# ---------------------------------------------------------
# 3. FIREWALL RULE: ALLOW JENKINS TRAFFIC
# ---------------------------------------------------------
resource "google_compute_firewall" "allow_jenkins" {
  name    = "allow-jenkins-8080"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080", "22"] # Allow Web UI and SSH
  }

  source_ranges = ["0.0.0.0/0"] # In production, restrict this to your Home IP!
  target_tags   = ["jenkins-server"]
}

# ---------------------------------------------------------
# 4. THE COMPUTE PLANE: GKE CLUSTER (Free Management Fee)
# ---------------------------------------------------------
resource "google_container_cluster" "primary" {
  name     = "devsecops-gke-cluster"
  location = "southamerica-west1-a" # Must be a single ZONE, not a region, to be free

  # We remove the default node pool to manage it securely via a custom pool
  remove_default_node_pool = true
  initial_node_count       = 1
  
  # Prevents accidental deletion of the cluster
  deletion_protection = false 
}

# ---------------------------------------------------------
# 5. GKE NODE POOL: SPOT VMs (Extreme Cost Savings)
# ---------------------------------------------------------
resource "google_container_node_pool" "spot_nodes" {
  name       = "gke-spot-pool"
  location   = "southamerica-west1-a"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    spot         = true        # Uses spare Google capacity for 60-90% discount
    machine_type = "e2-medium" # 2 vCPU, 4GB RAM (Minimum required for K8s)

    # Scopes define what GCP services the Kubernetes nodes can talk to
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# ---------------------------------------------------------
# 6. OUTPUTS
# ---------------------------------------------------------
output "jenkins_public_ip" {
  value       = google_compute_instance.jenkins_master.network_interface[0].access_config[0].nat_ip
  description = "The Public IP to access your Jenkins Dashboard"
}

output "gke_cluster_name" {
  value = google_container_cluster.primary.name
}
# questdb-devops
Quick Deployment of QuestDB with Envoy on the Cloud using Terraform and Docker

## Technology Stack
- **QuestDB**: High-performance time-series database
- **Envoy Proxy**: Used as TLS/SSL termination layer since QuestDB Community Edition doesn't support native TLS
- **Docker**: Container runtime for QuestDB and Envoy deployment
- **Docker Compose**: Container orchestration for multi-container deployment
- **Terraform**: Infrastructure as Code tool for cloud deployment
- **ZFS**: Advanced file system for data persistence
- **Google Cloud Platform**: Cloud infrastructure provider

## Prerequisites
- Ubuntu-based system (tested on Ubuntu 22.04 LTS)
- Google Cloud Platform account with billing enabled
- A GCP project with Compute Engine API enabled
- A secondary disk mounted at /dev/sdb for ZFS storage (will be created by Terraform)
- Terraform and gcloud CLI installed locally

## Architecture
- QuestDB runs in a Docker container handling time-series data storage and processing
- Envoy Proxy container acts as a reverse proxy providing:
  - TLS termination for HTTPS (port 9000)
  - TLS termination for PostgreSQL wire protocol (port 8812)
- ZFS provides reliable storage with compression and data integrity features

## Installation Steps

### 1. Local Environment Setup
```bash
# Install Terraform
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt-get install terraform

# Install Google Cloud CLI
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get update && sudo apt-get install google-cloud-cli
gcloud init
```

### 2. GCP Configuration
```bash
# Authenticate with GCP
gcloud auth application-default login

# Configure terraform.tfvars
cat > terraform/terraform.tfvars <<EOF
project_id = "your-project-id"
allowed_ip = "your-ip-address/32"
EOF
```

### 3. Infrastructure Deployment
```bash
cd terraform
terraform init
terraform plan    # Review the changes
terraform apply   # Deploy the infrastructure
```

### 4. Server Configuration
After the infrastructure is deployed, SSH into the created VM instance:
```bash
# Make setup script executable and run it
chmod +x setup.sh
./setup.sh

# Generate SSL certificates
cd questdb
chmod +x generate-certs.sh
./generate-certs.sh --name "your-domain-or-ip"

# Start the services
docker compose up -d
```

## SSL Certificate Management
- Self-signed certificates are generated in `questdb/certs/`
- Certificate files:
  - `cert.pem`: Public certificate
  - `key.pem`: Private key
- Default validity: 365 days
- To regenerate with custom settings:
```bash
./generate-certs.sh --country US --state California --locality "San Francisco" \
                   --org "Your Company" --name "your-domain.com" --valid 730
```

## Service URLs
- QuestDB Web Console: `https://<your-server-ip>:9000`
- PostgreSQL Interface: `postgresql://<your-server-ip>:8812`

## Troubleshooting
1. Certificate Issues:
   - Ensure both cert.pem and key.pem have 644 permissions
   - Verify certificate validity: `openssl x509 -in certs/cert.pem -text -noout`
2. Connection Issues:
   - Check GCP firewall rules (created by Terraform)
   - Verify Envoy logs: `docker logs envoy`
   - Verify QuestDB logs: `docker logs questdb`

## Data Management
- QuestDB data is stored in ZFS pool at /questdb_zfs
- ZFS features enabled:
  - LZ4 compression
  - Disabled access time updates
  - 12-bit ashift for modern drives

## Performance Tuning
Environment variables in docker-compose.yml optimize QuestDB for:
- Yearly data partitioning
- Optimized WAL and data append sizes
- Configured memory allocation for column operations

## Notes
- The setup script will install Docker, ZFS utilities, and configure the storage
- SSL certificates are required for secure communication
- Default ports: 9000 (HTTPS), 8812 (PostgreSQL)
- Data is persisted in a ZFS pool mounted at /questdb_zfs
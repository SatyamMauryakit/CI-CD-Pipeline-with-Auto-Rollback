# CI/CD Pipeline with Auto Rollback (Docker + GitHub Actions + AWS EC2)

A simple **Node.js (Express)** web app with a complete **CI/CD pipeline** using **GitHub Actions**, **Docker Hub**, and **AWS EC2** deployment.

This project demonstrates:
- Build & push a Docker image automatically on every push to `main`
- Deploy the latest image to an EC2 server using SSH
- Health endpoint (`/health`) for basic uptime checks
- A deployment flow that can support **auto-rollback** (you can extend it in `deploy.sh`)

---

## Tech Stack

- **Node.js + Express**
- **Docker**
- **Docker Hub**
- **GitHub Actions**
- **AWS EC2 (Ubuntu)**
- **appleboy/ssh-action** + **appleboy/scp-action**

---

## Project Structure

```bash
.
├── .github/workflows/deploy.yml   # GitHub Actions CI/CD workflow
├── Dockerfile                     # Docker image definition
├── Docker-compose.yml             # Compose file used on EC2
├── index.js                       # Express app
├── index.html                     # Frontend HTML page
├── package.json
└── package-lock.json
```

---

## Application Endpoints

Once running (locally or via Docker), the app listens on:

- **Home:** `GET /` → serves `index.html`
- **Health:** `GET /health` → returns `OK`

---

## Run Locally (without Docker)

### 1) Install dependencies
```bash
npm install
```

### 2) Start the server
```bash
node index.js
```

### 3) Open in browser
- http://localhost:3000
- Health check: http://localhost:3000/health

---

## Run with Docker (Local)

### Build image
```bash
docker build -t project-1:local .
```

### Run container
```bash
docker run -p 3000:3000 project-1:local
```

Open:
- http://localhost:3000
- http://localhost:3000/health

---

## CI/CD Pipeline (How it works)

Workflow file: `.github/workflows/deploy.yml`

On every push to the **`main`** branch, GitHub Actions will:

1. **Checkout code**
2. **Login to Docker Hub**
3. **Build and push Docker image**
   - Tag used: `${DOCKER_USERNAME}/project-1:latest`
4. **SSH into EC2** and install Docker (if needed)
5. **Copy `Docker-compose.yml` to the EC2 instance**
6. **Run deployment script (`deploy.sh`) on EC2**

---

## Required GitHub Secrets

Go to:
**Repo → Settings → Secrets and variables → Actions → New repository secret**

Add these secrets:

| Secret Name | Description |
|------------|-------------|
| `DOCKER_USERNAME` | Your Docker Hub username |
| `DOCKER_PASSWORD` | Your Docker Hub password or access token |
| `EC2_IP` | Public IPv4 address of your EC2 instance |
| `EC2_KEY` | Private SSH key (PEM content) for EC2 login |

> The workflow uses `username: ubuntu` on the server.

---

## EC2 Server Requirements

- Ubuntu EC2 instance
- Port **3000** open in Security Group (Inbound rules)
- SSH access enabled (port **22**)
- Docker installed (workflow tries to install it automatically)

---

## Important: `deploy.sh` is missing

Your workflow runs:

```bash
chmod +x deploy.sh
./deploy.sh
```

But there is **no `deploy.sh` file in the repository** currently.

### Option A (Recommended): Add `deploy.sh` to this repo
Create `deploy.sh` in the root and commit it.

Example `deploy.sh` (basic deploy using docker compose):

```bash
#!/usr/bin/env bash
set -e

export DOCKER_USERNAME="${DOCKER_USERNAME:-YOUR_DOCKER_USERNAME}"
export DOCKER_TAG="${DOCKER_TAG:-latest}"

cd ~/project-1

docker compose -f Docker-compose.yml pull
docker compose -f Docker-compose.yml up -d

docker ps
```

### Option B: Keep `deploy.sh` already present on EC2
If you already created it manually on the EC2 instance inside `~/project-1`, make sure it exists and is executable.

---

## Auto Rollback (Suggested Approach)

To implement true auto-rollback, you can enhance `deploy.sh` like this:

1. Deploy new version
2. Run a health check against `http://localhost:3000/health`
3. If health check fails:
   - revert to the previous image tag
   - restart containers

A simple approach is to tag images with:
- `latest`
- commit SHA (example: `project-1:<sha>`)
- `stable` (last known good)

Then rollback to `stable` if `/health` fails.

---

## Troubleshooting

### Docker Compose file name
Your repo uses: **`Docker-compose.yml`** (capital D)
Make sure all commands reference the exact case.

### Common issues
- EC2 security group not allowing port 3000
- Wrong `EC2_KEY` format (should be the private key content)
- Docker Hub credentials incorrect
- `deploy.sh` missing or not executable

---

## License
ISC (as defined in `package.json`)

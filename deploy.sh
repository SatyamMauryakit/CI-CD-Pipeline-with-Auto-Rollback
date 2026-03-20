#!/bin/bash

IMAGE="satyammaurya/project-1:latest"
ROLLBACK_IMAGE="satyammaurya/project-1:previous"
CONTAINER_NAME="devops-app"

echo "🚀 Starting deployment..."

cd ~/project-1 || exit

# 🔥 Step 1: Get currently running container image (CORRECT WAY)
CURRENT_IMAGE=$(docker inspect --format='{{.Config.Image}}' $CONTAINER_NAME 2>/dev/null)

if [ ! -z "$CURRENT_IMAGE" ]; then
    echo "📦 Saving rollback image from running container..."
    docker tag $CURRENT_IMAGE $ROLLBACK_IMAGE
else
    echo "  No running container found (first deployment)"
fi

# 🔥 Step 2: Pull latest image
echo "📥 Pulling latest image..."
docker pull $IMAGE

# 🔥 Step 3: Stop & remove old container
echo "🛑 Removing old container..."
docker rm -f $CONTAINER_NAME 2>/dev/null

# 🔥 Step 4: Run new container
echo "🚀 Running new container..."
docker run -d -p 3000:3000 --name $CONTAINER_NAME $IMAGE

# 🔥 Step 5: Wait for app
echo "⏳ Waiting for app..."
sleep 15

# 🔥 Step 6: Health check
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/health)

echo "Health status: $STATUS"

# 🔥 Step 7: Rollback if failed
if [ "$STATUS" != "200" ]; then
    echo "❌ Health check failed! Rolling back..."

    docker rm -f $CONTAINER_NAME 2>/dev/null

    if docker image inspect $ROLLBACK_IMAGE > /dev/null 2>&1; then
        echo "🔄 Starting rollback container..."
        docker run -d -p 3000:3000 --name $CONTAINER_NAME $ROLLBACK_IMAGE
    else
        echo "  No rollback image found!"
    fi

    exit 1
fi

echo "✅ Deployment successful!"

# 🔥 Step 8: Clean unused images (KEEP ONLY latest & previous)
echo "🧹 Cleaning unused images..."
docker image prune -f
~

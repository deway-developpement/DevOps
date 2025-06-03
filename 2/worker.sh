sudo apt-get update
sudo apt-get install -y curl


# The next steps focus on the green and yellow parts: 
# - Install Podman
# - Connect to Docker Hub
# - Pull and run an Ubuntu container
# - Install WordPress using Podman
# - Set up port direction from wordpress to guest@localhost:8080

# Install Podman
sudo apt-get -y install podman

# Pull and run an Ubuntu container
sudo podman run -d --name ubuntu-container -it docker.io/library/ubuntu:latest

# Deploy WordPress using Podman, with port direction to guest@localhost:8080
sudo podman run -d --name wordpress -p 8080:80 -e WORDPRESS_DB_HOST=localhost:3306 -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD=password -e WORDPRESS_DB_NAME=db docker.io/library/wordpress

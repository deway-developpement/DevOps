sudo apt-get update
sudo apt-get install -y curl


# The next steps focus on the green and yellow parts: 
# - Install Docker (this is for the GitLab Runner)
# - Install Podman
# - Connect to Docker Hub
# - Pull and run an Ubuntu container
# - Install WordPress using Podman
# - Set up port direction from wordpress to guest@localhost:8080

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
# Add user to Docker group
sudo usermod -aG docker $USER
# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker
# Print Docker version
echo "Docker version: $(docker --version | awk '{print $3}')"
# Install Docker Compose
sudo apt-get install -y docker-compose
# Print Docker Compose version
echo "Docker Compose version: $(docker-compose --version | awk '{print $3}')"

# Install Podman
sudo apt-get -y install podman

# TODO: uncomment the next 2 commands
# # Pull and run an Ubuntu container
# sudo podman run -d --name ubuntu-container -it docker.io/library/ubuntu:latest

# # Deploy WordPress using Podman, with port direction to guest@localhost:8080
# sudo podman run -d --name wordpress -p 8080:80 -e WORDPRESS_DB_HOST=localhost:3306 -e WORDPRESS_DB_USER=root -e WORDPRESS_DB_PASSWORD=password -e WORDPRESS_DB_NAME=db docker.io/library/wordpress


# Next, we will focus on the red part: 
# linking this Vagrant box to the other one
# by registering this box as a "Docker socket agent pool" for the other box's GitLab. 
# When the pipeline is triggered by the other box, a container will be created here to execute the job; at the end of the job, the container will be removed.

# Install GitLab Runner
# Download the binary for the system (architecture amd64)
sudo curl -L --output /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64

# Give it permission to execute
sudo chmod +x /usr/local/bin/gitlab-runner

# Create a GitLab Runner user
sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash

# Install and run as a service
sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
sudo gitlab-runner start

if [ ! -f /home/vagrant/runner_access_token.txt ]; then
    echo "Waiting for runner_access_token.txt to be created or modified..."
# Use inotifywait to await the access token
    inotifywait -m -e create -e modify /home/vagrant | while read path action file; do
    if [ "$file" = "runner_access_token.txt" ]; then
        break
    fi
done
fi

# Register the GitLab Runner, using the token from the file created by the other box
sudo gitlab-runner register --non-interactive --url http://192.168.56.10 --executor docker --docker-image "docker:latest" --token $(cat ~/runner_access_token.txt) 


sudo apt-get update
sudo apt-get install -y curl

# Disable Apache2
sudo systemctl stop apache2
sudo systemctl disable apache2

# Install Gitlab
curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
sudo EXTERNAL_URL="http://localhost" apt-get install -y gitlab-ce

# Configure Gitlab
sudo gitlab-ctl reconfigure

# Enable and start Gitlab service
sudo systemctl enable gitlab-runsvdir
sudo systemctl start gitlab-runsvdir

# Print Gitlab status
sudo gitlab-ctl status
# Print Gitlab version
gitlab_version=$(gitlab-rake gitlab:env:info | grep "GitLab version" | awk '{print $3}')
echo "GitLab version: $gitlab_version"
# Print Gitlab URL
echo "GitLab is running at http://localhost"

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
# Add user to Docker group
sudo usermod -aG docker $USER
# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker
# Print Docker version
docker_version=$(docker --version | awk '{print $3}')
echo "Docker version: $docker_version"

# Install Docker Compose
sudo apt-get install -y docker-compose
# Print Docker Compose version
docker_compose_version=$(docker-compose --version | awk '{print $3}')
echo "Docker Compose version: $docker_compose_version"


# Create a bitwarden gitlab project
gitlab_project_name="bitwarden"
gitlab_project_description="Bitwarden project for secure password management"

# Get token from gitlab rails console
gitlab_token=$(sudo gitlab-rails runner 'token = User.find_by_username("root").impersonation_tokens.create!(name: "auto-token", scopes: [:api], expires_at: 1.year.from_now); puts token.token')

# Create a new project using GitLab API
curl --request POST "http://localhost/api/v4/projects" \
     --header "PRIVATE-TOKEN: $gitlab_token" \
     --form "name=$gitlab_project_name" \
     --form "description=$gitlab_project_description" \
     --form "visibility=private"

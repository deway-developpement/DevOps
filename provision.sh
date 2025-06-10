export vm1=192.168.56.10
export vm2=192.168.56.11

sudo apt-get update
sudo apt-get install -y curl

# Disable Apache2
sudo systemctl stop apache2
sudo systemctl disable apache2

# Install Gitlab
curl -s https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash
sudo EXTERNAL_URL="http://$vm1" apt-get install -y gitlab-ce

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
echo "GitLab is running at http://$vm1"

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

# Create a directory for GitLab 
mkdir -p ~/gitlab


# Create a bitwarden gitlab project
gitlab_project_name="bitwarden"
gitlab_project_description="Bitwarden project for secure password management"

# Generate a random token for GitLab API access
token_name="automation_token"
token_string="outgoing-affix-trustless-hubcap-borax"
token=$(openssl rand -base64 32 | tr -d '/+' | cut -c1-32)
scopes="'api', 'sudo'"

# Print the generated token
echo "Generated token: $token"

# Get token from gitlab rails console
export gitlab_token=$(sudo gitlab-rails runner "token = User.find_by_username('root').personal_access_tokens.create(scopes: [$scopes],name: '$token_name',expires_at: 365.days.from_now); token.set_token('$token'); token.save!; puts token.token") && \
echo "GitLab token: $gitlab_token"  # Print the GitLab token

# Create a new project using GitLab API
curl --request POST "http://$vm1/api/v4/projects" \
     --header "PRIVATE-TOKEN: $gitlab_token" \
     --form "name=$gitlab_project_name" \
     --form "description=$gitlab_project_description" \
     --form "visibility=private"

# Clone the Bitwarden repository into the newly created project
sudo -i
git clone https://github.com/bitwarden/server.git /var/opt/gitlab/git-data/repositories/$(whoami)/$gitlab_project_name.git && \
# Change ownership of the repository to GitLab user
chown -R git:git /var/opt/gitlab/git-data/repositories/$(whoami)/$gitlab_project_name.git && \
# Push the Bitwarden repository contents to the GitLab project
cd /var/opt/gitlab/git-data/repositories/$(whoami)/$gitlab_project_name.git && \
git remote set-url origin "http://$(whoami):$token@$vm1/$(whoami)/$gitlab_project_name.git" && \
git push -u origin --all

echo "GitLab project '$gitlab_project_name' has been created and initialized with the Bitwarden repository."


# Create a new GitLab instance runner
# and get the access token from the JSON response
sudo apt-get install jq -y  # for parsing JSON
curl --request POST "http://$vm1/api/v4/user/runners" \
  --header "PRIVATE-TOKEN: $gitlab_token" \
  --form "runner_type=instance_type" | jq -r '.token' | tee ~/gitlab/runner_access_token.txt

# Send the GitLab Runner token to the other VM
sudo apt-get install -y sshpass  # for SSH authentication via password
# Send the file with "scp" via SSH (using the password "vagrant" for authentication), 
#  without checking the host key, 
#  at the destination path "~/runner_access_token.txt" on the other VM
sshpass -p "vagrant" scp -o StrictHostKeyChecking=no ~/gitlab/runner_access_token.txt vagrant@$vm2:~/runner_access_token.txt && echo "File sent to $vm2"



# pour le tp3, il faudra créer un serveur de production. Au choix : 
# - 3e vm
# - static
# - docker file push puis récupéré dans vm2
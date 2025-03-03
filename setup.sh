#!/bin/bash

set -e

# TODO: Set to URL of git repo.
PROJECT_GIT_URL='https://github.com/ptobou/profiles-rest-api.git'
PROJECT_BASE_PATH='/usr/local/apps/profiles-rest-api'

echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y python3-dev python3-venv sqlite3 libsqlite3-dev python3-pip supervisor nginx git
sudo apt-get install -y python3.12-dev build-essential libpcre3 libpcre3-dev

# Create project directory
mkdir -p $PROJECT_BASE_PATH
git clone $PROJECT_GIT_URL $PROJECT_BASE_PATH

# Create and activate virtual environment
python3 -m venv $PROJECT_BASE_PATH/venv
source $PROJECT_BASE_PATH/venv/bin/activate

# Install python packages
pip install -r $PROJECT_BASE_PATH/requirements.txt
pip install gunicorn==21.2.0

# Run migrations and collect static files
cd $PROJECT_BASE_PATH
python manage.py migrate
python manage.py collectstatic --noinput

# Configure Supervisor
cp $PROJECT_BASE_PATH/deploy/supervisor_profiles_api.conf /etc/supervisor/conf.d/profiles_api.conf
supervisorctl reread
supervisorctl update
supervisorctl start profiles_api  # Ensure the server starts

# Configure Nginx
cp $PROJECT_BASE_PATH/deploy/nginx_profiles_api.conf /etc/nginx/sites-available/profiles_api.conf
rm -f /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/profiles_api.conf /etc/nginx/sites-enabled/profiles_api.conf
systemctl restart nginx

echo "Deployment complete! Server is running."

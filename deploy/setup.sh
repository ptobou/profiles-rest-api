#!/usr/bin/venv bash

set -e

# TODO: Set to URL of git repo.
# PROJECT_GIT_URL='git@github.com:ptobou/profiles-rest-api.git'
PROJECT_GIT_URL='https://github.com/ptobou/profiles-rest-api.git'


PROJECT_BASE_PATH='/usr/local/apps/profiles-rest-api'

echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y python3-dev python3-venv sqlite3 libsqlite3-dev python3-pip supervisor nginx git
sudo apt update && sudo apt install -y python3.12-dev build-essential libpcre3 libpcre3-dev
sudo apt update
sudo apt install -y python3-dev python3-pip python3-venv build-essential libpcre3 libpcre3-dev
sudo pip install --no-binary :all: uwsgi

# Create project directory
mkdir -p $PROJECT_BASE_PATH
git clone $PROJECT_GIT_URL $PROJECT_BASE_PATH

# Create virtual environment
mkdir -p $PROJECT_BASE_PATH/venv
python3 -m venv $PROJECT_BASE_PATH/venv

# Install python packages
$PROJECT_BASE_PATH/venv/bin/pip install -r $PROJECT_BASE_PATH/requirements.txt
$PROJECT_BASE_PATH/venv/bin/pip install uwsgi==2.0.18

# Run migrations and collectstatic
cd $PROJECT_BASE_PATH
$PROJECT_BASE_PATH/venv/bin/python manage.py migrate
$PROJECT_BASE_PATH/venv/bin/python manage.py collectstatic --noinput

# Configure supervisor
cp $PROJECT_BASE_PATH/deploy/supervisor_profiles_api.conf /etc/supervisor/conf.d/profiles_api.conf
supervisorctl reread
supervisorctl update
supervisorctl restart profiles_api

# Configure nginx
cp $PROJECT_BASE_PATH/deploy/nginx_profiles_api.conf /etc/nginx/sites-available/profiles_api.conf
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/profiles_api.conf /etc/nginx/sites-enabled/profiles_api.conf
systemctl restart nginx.service

echo "DONE! :)"

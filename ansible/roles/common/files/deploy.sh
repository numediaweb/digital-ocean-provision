#!/bin/bash

echo ">>>> Deploy app.snfreports.com"

#Configuration
project_path="/var/www"
deploy_history_file="/var/www/deploy_history.txt"

#Variables
current_path="$project_path/current"
releases_path="$project_path/releases"
timestamp=$(date +%s)
deploy_path="$releases_path/$timestamp"

#Tasks
echo ">>>> Create ${deploy_path}"
export SYMFONY_ENV=prod
sudo mkdir -p $deploy_path
sudo chown -R www-data:www-data $deploy_path

sudo ln -sfn $deploy_path $current_path

sudo setfacl -R -m u:www-data:rX $deploy_path
sudo setfacl -R -m u:www-data:rwX "${deploy_path}/var/cache"
sudo setfacl -dR -m u:www-data:rwX "${deploy_path}/var/cache"

#Previous releases cleanup

echo ">>>> Cleaning Previous releases"
cd $releases_path
sudo ls -lah | awk '{print$9}' | sort -nr | sed 1,5d | grep "^[0-9].*" | sudo xargs rm -fr

echo "$(date +"%d.%m.%Y %k:%M:%S")      ${readable_time}        $branch" >> $deploy_history_file
echo ">>>> Successfully deployed     ${deploy_path}  ${readable_time}        ${branch}"
echo
echo ">>>> HardDisk space"
df -h
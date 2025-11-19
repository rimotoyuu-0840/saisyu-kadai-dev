#!/bin/bash
# ---------------------------------
# EC2 user data
# Autoscaling startup scripts.
# ---------------------------------
APP_NAME=tastylog
BUCKET_NAME=tastylog-dev-deploy-bucket-al1bpc
CWD=/home/ec2-user

# Log output setting
LOGFILE="/var/log/initialize.log"
exec > "${LOGFILE}"
exec 2>&1

# Change current work directory
cd ${CWD}

# ---------------------------------
# Get DB connection info from SSM Parameter Store
# ---------------------------------
PROJECT="tastylog"
ENV="dev"

DB_HOST=$(aws ssm get-parameter --name "/${PROJECT}/${ENV}/app/MYSQL_HOST" --query "Parameter.Value" --output text)
DB_PORT=$(aws ssm get-parameter --name "/${PROJECT}/${ENV}/app/MYSQL_PORT" --query "Parameter.Value" --output text)
DB_NAME=$(aws ssm get-parameter --name "/${PROJECT}/${ENV}/app/MYSQL_DATABASE" --query "Parameter.Value" --output text)
DB_USER=$(aws ssm get-parameter --name "/${PROJECT}/${ENV}/app/MYSQL_USERNAME" --with-decryption --query "Parameter.Value" --output text)
DB_PASS=$(aws ssm get-parameter --name "/${PROJECT}/${ENV}/app/MYSQL_PASSWORD" --with-decryption --query "Parameter.Value" --output text)

# ---------------------------------
# Create .env file for Node.js
# ---------------------------------
mkdir -p /opt/${APP_NAME}
cat <<EOF > /opt/${APP_NAME}/.env
DB_HOST=${DB_HOST}
DB_PORT=${DB_PORT}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASS}
EOF

# ---------------------------------
# Get latest app package from S3
# ---------------------------------
aws s3 cp s3://${BUCKET_NAME}/latest ${CWD}
aws s3 cp s3://${BUCKET_NAME}/${APP_NAME}-app-$(cat ./latest).tar.gz ${CWD}

# Decompress tar.gz
rm -rf ${CWD}/${APP_NAME}
mkdir -p ${CWD}/${APP_NAME}
tar -zxvf "${CWD}/${APP_NAME}-app-$(cat ./latest).tar.gz" -C "${CWD}/${APP_NAME}"

# Move to application directory
sudo rm -rf /opt/${APP_NAME}
sudo mv ${CWD}/${APP_NAME} /opt/

# Boot application 
sudo systemctl enable tastylog
sudo systemctl restart tastylog

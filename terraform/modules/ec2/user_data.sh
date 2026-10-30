#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
dnf update -y
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent
 
echo "ECS_CLUSTER=cloudsave-cluster-${{local.prefix}}" > /etc/ecs/ecs.config
systemctl restart cloud-final.service
systemctl restart ecs

systemctl enable ecs
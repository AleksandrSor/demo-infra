ssm plugin install
```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb" -o "session-manager-plugin.deb" && \
sudo dpkg -i session-manager-plugin.deb
```

ssm plugin use
```bash
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].[InstanceId, InstanceType, Placement.AvailabilityZone, State.Name, PrivateIpAddress]' \
  --output table

aws ssm start-session --target xxx
```
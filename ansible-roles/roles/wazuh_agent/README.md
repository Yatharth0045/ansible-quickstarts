## Manual Steps

<!-- Setup Wazuh Server : Amazon Linux -->
```bash
sudo rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH

sudo tee /etc/yum.repos.d/wazuh.repo > /dev/null << EOL
[wazuh]
name=Wazuh repository
baseurl=https://packages.wazuh.com/4.x/yum/
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
EOL

sudo yum install wazuh-manager -y

# sudo tee /var/ossec/etc/ossec.conf > /dev/null << EOL
# <ossec_config>
#   <global>
#     <white_list>127.0.0.1</white_list>
#     <white_list>::1</white_list>
#   </global>

#   <remote>
#     <connection>secure</connection>
#     <port>1514</port>
#   </remote>
# </ossec_config>
# EOL

sudo systemctl enable wazuh-manager
sudo systemctl start wazuh-manager
sudo systemctl restart wazuh-agent
sudo systemctl status wazuh-manager
```

<!-- AL2023-AMD | AL2023-ARM -->
```bash
sudo rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH

sudo tee /etc/yum.repos.d/wazuh.repo > /dev/null << EOL
[wazuh]
name=Wazuh repository
baseurl=https://packages.wazuh.com/4.x/yum/
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
EOL

sudo yum install wazuh-agent -y

sudo sed -i s/MANAGER_IP/52.201.252.153/g /var/ossec/etc/ossec.conf

sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
sudo systemctl restart wazuh-agent
sudo systemctl status wazuh-agent
```

<!-- Ubuntu-AMD | Ubuntu-ARM -->
```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

apt-get update -y
apt-get install wazuh-agent -y

sudo sed -i s/MANAGER_IP/52.201.252.153/g /var/ossec/etc/ossec.conf

sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
sudo systemctl restart wazuh-agent
sudo systemctl status wazuh-agent
```

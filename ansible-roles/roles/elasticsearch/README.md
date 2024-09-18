## Manual Steps

```bash
elasticsearch_version: "6.8.23"
es_cluster_name: "preprod"
es_node_master: true
es_node_data: false
es_node_ingest: false
es_network_host: "0.0.0.0"
ansible_become: true
```

<!-- AL2023-AMD -->
```bash
sudo yum install -y java-11-amazon-corretto-headless
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

sudo tee /etc/yum.repos.d/elasticsearch.repo <<EOF
[elasticsearch]
name=Elasticsearch repository
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

sudo dnf update
sudo dnf -y install elasticsearch-6.8.23
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service

sudo tee /etc/elasticsearch/elasticsearch.yml <<EOF
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
cluster.name: demo
node.name: master-1
network.host: 0.0.0.0
discovery.zen.ping.unicast.hosts:
  - 44.214.179.0
  - 44.203.34.45
  - 44.202.187.136
discovery.zen.minimum_master_nodes: 2
xpack.ml.enabled: false
node.master: true
http.port: 9200
EOF

sudo systemctl start elasticsearch.service
sudo systemctl status elasticsearch.service
sudo systemctl restart elasticsearch.service
```
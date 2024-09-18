Role Name: node_exporter
=========

- Node Groups: 
    `node_exporter`
    `amd_instances`
    `arm_instances`

To deploy the role

```bash
cd ansible-roles
ansible-playbook playbook.yml -i inventory
```

Role Name: elasticsearch
=========

- Node Groups:
    `elastic_search`
    `elastic_search_master`
    `elastic_search_data`
    `elastic_search_client`

To deploy the role

```bash
cd ansible-roles
ansible-playbook playbook.yml -i inventory
```

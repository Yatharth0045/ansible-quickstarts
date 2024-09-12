## Ansible-quickstart

### Pre-requisites

1. Launch EC2s

    1. Create AWS IAM User with admin permission and create security credentials: [AWS IAM](https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#/security_credentials?section=IAM_credentials)

    2. Setup aws access and secret credentials
    ```bash
        ## Configure access and secret keys
        aws configure --profile kodekloud

        ## Export Profile and Region
        export AWS_PROFILE=kodekloud
        export AWS_REGION='us-east-1'
    ```

    3. Run the `pre-requisites.sh` script
    ```bash
        ./pre-requisites.sh
    ```

### Install Ansible

- Install with dnf : `sudo dnf install -y ansible`
- Install with apt : `sudo apt install -y ansible`

### Run module `ping`
1. Create `inventory` on controller node as `ansible_basics/inventory`
2. Run `ping` module as follows
    ```bash
        ansible all -i inventory -m ping
        ansible aws_remote -i inventory -m ping
        ansible local -i inventory -m ping
    ```

### Cleanup

1. Run the cleanup script
```bash
    ./cleanup.sh
```

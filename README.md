0. My demo cheat sheet

```

## check all service is up and running
sudo systemctl status nvidia_gpu_exporter prometheus grafana dcgm-exporter ollama
ls -l /etc/systemd/system/{nvidia_gpu_exporter,prometheus,grafana,dcgm-exporter,ollama}.service

curl localhost:9090/metrics
curl localhost:9835/metrics
curl localhost:9400/metrics

Grafana UI: admin / StrongPassword123!

Docker main ip 172.17.0.1

$ ip a
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default
    link/ether 8a:95:c3:32:53:0c brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever

Grafana Dashboard
https://grafana.com/grafana/dashboards/14574-nvidia-gpu-metrics/
https://grafana.com/grafana/dashboards/12239-nvidia-dcgm-exporter-dashboard/

### ollama pull models, on the GPU VM
sudo docker exec -it ollama-container ollama pull qwen3:0.6b
sudo docker exec -it ollama-container ollama pull deepseek-r1:latest

docker run --name=ollama-container-2 -d \
  --gpus all \
  -v ollama-data:/root/.ollama \
  -p 11435:11434 \
  ollama/ollama

docker run --name=ollama-container-3 -d \
  --gpus all \
  -v ollama-data:/root/.ollama \
  -p 11436:11434 \
  ollama/ollama

curl -s -X POST http://localhost:11435/api/generate -d '{
  "model": "qwen3:0.6b",
  "prompt": "Why is the sky blue?",
  "stream": false
}'

curl -s -X POST http://localhost:11436/api/generate -d '{
  "model": "qwen3:0.6b",
  "prompt": "Why is the sky blue?",
  "stream": false
}'

docker stop ollama-container ollama-container-2 ollama-container-3

```

1. install tools

```bash
## Assuming you are using homebrew
brew install awscli tfenv

aws sso login

### import ssh key to AWS
ssh-keygen            ## if you don't have first key pair yet
cat ~/.ssh/id_rsa.pub ## copy and patse the out and import key to AWS -> EC2 -> Network & Security (Key Pairs)

tfenv install 1.12.1

```


2. downloading repo

```bash
git clone https://github.com/teochenglim/aws-gpu
cd aws-gpu
tfenv use 1.12.1
code .

```

3. terraform

```bash

### review variable file 
vi terraform.tfvars

### terraform in 3 steps
terraform init
terraform plan
terraform apply

### check the tips
terraform output

### delete resource when no longer needed
terraform destroy

```

4. extra

```bash
## if you are not using aws optimised gpu instance but just ubuntu
sudo apt install ubuntu-drivers-common ## install ubuntu-drivers tools
sudo ubuntu-drivers autoinstall ## install GPU with auto detect

## query about GPU ami id in your region, remember to switch region
aws ec2 describe-images --region ap-southeast-1 \
      --owners amazon \
      --filters 'Name=name,Values=Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04) ????????' 'Name=state,Values=available' \
      --query 'reverse(sort_by(Images, &CreationDate))[:1].ImageId' \
      --output text
```
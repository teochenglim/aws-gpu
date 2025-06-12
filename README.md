# NVidia GPU Monitoring in AWS

## Overview

This repo uses Terraform to create a small network with a public subnet that has a spot instance running inside it.  The EC2 instance uses userdata to set up and configure docker to run containers for prometheus, grafana, nvidia-exporter and ollama.  If you run the Terraform and deploy the resources you should be able to see them in your AWS account and have access to login to Grafana via your web browser (restricted to your public IP address) and view the Nvidia GPU metrics.  You can run one or more ollama containers to generate load which will affect the metrics shown in Grafana.

## Prerequisites

### AWS and Terraform Assumptions

To run this code we assume you already have access to an AWS account and know how to authenticate with it programmatically using the AWS CLI.  We also assume you have some understanding of how Terraform works.

### AWS CLI install

If you are running a Mac you can install awscli and tfenv using the following commands.

```bash
## Assuming you are using homebrew
brew install awscli tfenv

aws sso login

tfenv install 1.12.1
```

Please refer to Hashicorp's website on how to install Terraform.

### Terraform Variables

We recommend looking at the terraform.tfvars file which has all the variables and make changes as per your preferences before running any Terraform commands.

### AWS Keypair

You will need to create an AWS key pair in the AWS Console and update the terraform.tfvars file with it's reference.  You can create it using the AWS Console or use the example script below to also create a key pair and import the public key into the key pair section in the AWS Console.

```bash
### import ssh key to AWS
ssh-keygen            ## if you don't have first key pair yet
cat ~/.ssh/id_rsa.pub ## copy and paste the out and import key to AWS -> EC2 -> Network & Security (Key Pairs)
```

## Running Terraform

Assuming you're already programmatically logged into to AWS using the AWS cli you can now run the following Terraform commands.  It's worth noting that you will receive an error relating to the spot price, in the error it will display the minimum price which you can update the terraform.tfvars file with and rerun the Terraform command which should now complete successfully.

```bash
### terraform in 3 steps
terraform init
terraform plan
terraform apply

### check the helpful output
terraform output

### delete resources when no longer needed
terraform destroy
```

## Verification of AWS Resoures

You can log into the AWS Console and see the VPC, subnet, route table and EC2 instance which should have been created.

## Validating EC2 Instance Userdata has Worked

You should be able to log into your EC2 instance using your SSH key pair you created earlier.  You can run the following to confirm that you are using an Nvidia GPU.

```bash
nvidia-smi
```

It's important to note that the Terraform will complete before the userdata will have finished so if you try and access the URL for grafana or prometheus it may not be available because docker may still be downloading the container images (maybe give it 5 minutes after the Terraform has completed).

You can run the following to check on the state of the services (the docker containers are running as systemd services to make it more stable and provide the cabaility to self heal from failure). 

```bash
## check all service is up and running
sudo systemctl status nvidia_gpu_exporter prometheus grafana dcgm-exporter ollama
ls -l /etc/systemd/system/{nvidia_gpu_exporter,prometheus,grafana,dcgm-exporter,ollama}.service
```

You can also check the monitoring metrics are available for prometheus to scrape:

```bash
curl localhost:9090/metrics
curl localhost:9835/metrics
curl localhost:9400/metrics
```

### Accessing and Configuring Grafana

From the Terraform outputs you should be able to identify the Grafana URL, try logging in using the credentials admin / StrongPassword123! (these are set in the userdata template when setting up Grafana).

Once logged in you will need to set up the prometheus datasource, use the value http://localhost:9090/ and click save and test.  Hopefully it will recognise Prometheus running locally.

Now you can go to dashboards and import one or both of the following dashboards (they should be recognisable simply by pasting in the numerical reference, e.g. 14574), select prometheus as the datasource:

https://grafana.com/grafana/dashboards/14574-nvidia-gpu-metrics/
https://grafana.com/grafana/dashboards/12239-nvidia-dcgm-exporter-dashboard/

You should now see the Grafana dashboard(s).

## Running Ollama to Generate Load

If you wish to run some load on the EC2 instance to affect the GPU metrics you can use Ollama, see script options below.

```bash
## pull models, on the GPU VM
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

## Miscellaneous

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
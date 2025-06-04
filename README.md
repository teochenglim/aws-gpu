0. My demo cheat sheet

```

## check all service is up and running
sudo systemctl status nvidia_gpu_exporter prometheus grafana dcgm-exporter
ls -l /etc/systemd/system/{nvidia_gpu_exporter,prometheus,grafana,dcgm-exporter}.service

curl localhost:9090/metrics
curl localhost:9835/metrics
curl localhost:9400/metrics

Grafana UI: admin / StrongPassword123!

Docker main ip 172.17.0.1

https://grafana.com/grafana/dashboards/14574-nvidia-gpu-metrics/
https://grafana.com/grafana/dashboards/12239-nvidia-dcgm-exporter-dashboard/

```

1. install tools

```
## Assuming you are using homebrew
brew install awscli tfenv

tfenv install 1.12.1
tfenv use 1.12.1


```


2. downloading repo

```
git clone https://github.com/teochenglim/aws-gpu
cd aws-gpu
code .

```

3. terraform

```

terraform init
terraform plan
terraform apply

terraform output

### delete resource
terraform destroy

```
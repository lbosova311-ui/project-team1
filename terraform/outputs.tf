output "vm_ip" {
  value = aws_instance.vm.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "grafana_url" {
  value = "http://${aws_instance.monitoring.public_ip}:3000"
}

output "prometheus_url" {
  value = "http://${aws_instance.monitoring.public_ip}:9090"
}
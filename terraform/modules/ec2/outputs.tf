output "jenkins_public_ip" { 
  value = aws_instance.jenkins.public_ip
}
output "ec2_arn"{
  value = aws_instance.jenkins.arn
}
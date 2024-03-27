# Output of elastic ip of ec2 provisioned 

output "e_ip" {
  value = aws_eip.static_eip.public_ip
}
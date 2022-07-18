#output "dns_1" {
#    description = "URL de acceso 1"
#    value       = "http://${aws_instance.servidor1.public_dns}"
#}

#output "dns_2" {
#    description = "URL de acceso 2"
#    value       = "http://${aws_instance.servidor2.public_dns}"
#}

output "balanceador" {
    description = "URL de acceso Balanceador"
    value       = "http://${aws_lb.alb.dns_name}"
}
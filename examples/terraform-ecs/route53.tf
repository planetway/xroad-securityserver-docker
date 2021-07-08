data "aws_route53_zone" "public" {
  name = var.public_zone_name
}

data "aws_route53_zone" "private" {
  name = var.private_zone_name
  private_zone = true
}

resource "aws_route53_record" "external" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "ss"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.external.dns_name]
}

resource "aws_route53_record" "internal" {
  zone_id = data.aws_route53_zone.private.zone_id
  name    = "ss-internal"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.internal.dns_name]
}

output "aws_lb_external_endpoint" {
  description = "SS public endpoint domain name"
  value = aws_route53_record.external.fqdn
}

output "aws_lb_internal_endpoint" {
  description = "SS private endpoint domain name"
  value = aws_route53_record.internal.fqdn
}

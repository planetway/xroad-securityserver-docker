resource "aws_lb_target_group" "external_5500" {
  name = "${var.name_prefix}-external-5500"
  port = 5500
  protocol = "TCP"
  target_type = "ip"
  vpc_id = data.aws_vpc.this.id
  health_check {
    port = 5588
    healthy_threshold = 3
    unhealthy_threshold = 3
    interval = 30
    # timeout is 10 seconds
  }
}

resource "aws_lb_target_group" "external_5577" {
  name = "${var.name_prefix}-external-5577"
  port = 5577
  protocol = "TCP"
  target_type = "ip"
  vpc_id = data.aws_vpc.this.id
  health_check {
    port = 5588
    healthy_threshold = 3
    unhealthy_threshold = 3
    interval = 30
    # timeout is 10 seconds
  }
}

resource "aws_lb_target_group" "internal_80" {
  name = "${var.name_prefix}-internal-80"
  port = 80
  protocol = "TCP"
  target_type = "ip"
  vpc_id = data.aws_vpc.this.id
  health_check {
    port = 5588
    healthy_threshold = 3
    unhealthy_threshold = 3
    interval = 30
    # timeout is 10 seconds
  }
}

resource "aws_lb_target_group" "internal_443" {
  name = "${var.name_prefix}-internal-443"
  port = 443
  protocol = "TCP"
  target_type = "ip"
  vpc_id = data.aws_vpc.this.id
  health_check {
    port = 5588
    healthy_threshold = 3
    unhealthy_threshold = 3
    interval = 30
    # timeout is 10 seconds
  }
}

resource "aws_lb_target_group" "internal_4000" {
  name = "${var.name_prefix}-internal-4000"
  port = 4000
  protocol = "TCP"
  target_type = "ip"
  vpc_id = data.aws_vpc.this.id
  health_check {
    port = 5588
    healthy_threshold = 3
    unhealthy_threshold = 3
    interval = 30
    # timeout is 10 seconds
  }
}

resource "aws_lb_listener" "external_5500" {
  load_balancer_arn = aws_lb.external.arn
  port              = "5500"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external_5500.arn
  }
}

resource "aws_lb_listener" "external_5577" {
  load_balancer_arn = aws_lb.external.arn
  port              = "5577"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.external_5577.arn
  }
}

resource "aws_lb_listener" "internal_80" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_80.arn
  }
}

resource "aws_lb_listener" "internal_443" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_443.arn
  }
}

resource "aws_lb_listener" "internal_4000" {
  load_balancer_arn = aws_lb.internal.arn
  port              = "4000"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_4000.arn
  }
}

resource "aws_lb" "external" {
  name               = "${var.name_prefix}-external"
  internal           = false
  load_balancer_type = "network"
  subnets            = data.aws_subnet_ids.public.ids

  enable_deletion_protection = var.termination_protection
  enable_cross_zone_load_balancing = true

  // TODO
  // access_logs {
  //   bucket  = aws_s3_bucket.lb_logs.bucket
  //   prefix  = "test-lb"
  //   enabled = true
  // }
}

resource "aws_lb" "internal" {
  name               = "${var.name_prefix}-internal"
  internal           = true
  load_balancer_type = "network"
  subnets            = data.aws_subnet_ids.private.ids

  enable_deletion_protection = var.termination_protection
  enable_cross_zone_load_balancing = true

  // TODO
  // access_logs {
  //   bucket  = aws_s3_bucket.lb_logs.bucket
  //   prefix  = "test-lb"
  //   enabled = true
  // }
}

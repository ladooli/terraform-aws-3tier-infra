resource "aws_lb" "main" {
  name               = "${var.project_name}-nlb"
  internal           = false 
  load_balancer_type = "network"
  subnets            = [for s in aws_subnet.public : s.id]

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-nlb"
  }
}

resource "aws_lb_target_group" "servers" {
  name     = "${var.project_name}-tg"
  port     = 80        
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    protocol            = "TCP"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

resource "aws_lb_target_group_attachment" "servers" {
  count            = length(aws_instance.server)
  target_group_arn = aws_lb_target_group.servers.arn
  target_id        = aws_instance.server[count.index].id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.servers.arn
  }
}

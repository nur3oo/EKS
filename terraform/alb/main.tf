resource "aws_lb" "alb" {
    name               = "eks-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public[*].id]

  enable_deletion_protection = false
  
}

resource "aws_lb_target_group" "alb-tg" {
  name     = "eks-tg"
  port     = var.port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  

  health_check {
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = var.health_check_path
    matcher             = var.matcher
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


resource "aws_lb_listener" "https" {

  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   =....

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg.arn
  }
}



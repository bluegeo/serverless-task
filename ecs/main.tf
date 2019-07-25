/*
VPC & Subnets
*/
// Availability zones in current region
data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = "${var.vpc_cidr}"

  tags {
    Name = "${var.app_name}-${var.environment}-tasks"
    Environment = "${var.app_name}-${var.environment}"
  }
}

// Private subnet for use by ALB
resource "aws_subnet" "private" {
  count             = "${var.az_count}"
  cidr_block        = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id            = "${aws_vpc.main.id}"

  tags {
    Name = "${var.app_name}-${var.environment}-tasks"
    Environment = "${var.app_name}-${var.environment}"
  }
}

resource "aws_lb" "tasks" {
  name = "${var.app_name}-${var.environment}-tasks"
  internal = true
  load_balancer_type = "network"
  subnets = [
    "${aws_subnet.private.*.id}"
  ]

  enable_deletion_protection = false // change this once intial development is complete

  tags {
    Name = "${var.app_name}-${var.environment}-tasks"
    Environment = "${var.app_name}-${var.environment}"
  }
}
output "load_balancer_arn" {
  value = "${aws_lb.tasks.arn}"
}
output "nlb_dns" {
  value = "${aws_lb.tasks.dns_name}"
}

// ELB Target Group
resource "aws_lb_target_group" "tasks" {
  name        = "${var.app_name}-${var.environment}-tasks"
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.main.id}"
}

// Redirect all traffic from the ALB to the target group
resource "aws_lb_listener" "tasks" {
  depends_on = ["aws_lb.tasks", "aws_lb_target_group.tasks"]

  load_balancer_arn = "${aws_lb.tasks.arn}"
  port              = "3000"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.tasks.arn}"
    type             = "forward"
  }
}

/*
ECS & Fargate Infrastructure
*/
// Cluster
resource "aws_ecs_cluster" "tasks" {
  name = "${var.app_name}-${var.environment}-tasks"

  tags {
    Name = "${var.app_name}-${var.environment}-tasks"
    Environment = "${var.app_name}-${var.environment}"
  }
}

// Task Definitions - means to run specific docker containers
data "template_file" "task_defn" {
  count = "${length(var.task_names)}"

  template = "${file("${path.root}/ecs/task-definitions/tasks.json")}"

  vars {
    task_name       = "${var.task_names[count.index]}"
    task_image      = "${var.task_names[count.index]}"
    fargate_cpu    = "${var.cpu[count.index]}"
    fargate_memory = "${var.memory[count.index]}"
    repo_name      = "${var.ecr_repo_name}"
  }
}

resource "aws_ecs_task_definition" "tasks" {
  count = "${length(var.task_names)}"

  family                = "${var.app_name}-${var.environment}"
  container_definitions = "${data.template_file.task_defn.*.rendered[count.index]}"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"  // Must be awsvpv for FARGATE

  cpu = "${var.cpu[count.index]}"
  memory = "${var.memory[count.index]}"

  // What roles the docker containers assume
  execution_role_arn = "${var.task_role_arn}"

  tags {
    Name = "${var.app_name}-${var.environment}-tasks"
    Environment = "${var.app_name}-${var.environment}"
  }
}

resource "aws_security_group" "tasks" {
  name = "${var.app_name}-${var.environment}"
  description = "Security group for services"
  vpc_id = "${aws_vpc.main.id}"

  // HTTP
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Service -
resource "aws_ecs_service" "tasks" {
  depends_on = [
    "aws_security_group.tasks",
    "aws_ecs_task_definition.tasks",
    "aws_lb_listener.tasks"
  ]

  count = "${length(var.task_names)}"

  name            = "${var.app_name}-${var.environment}"
  cluster         = "${aws_ecs_cluster.tasks.id}"
  task_definition = "${aws_ecs_task_definition.tasks.*.arn[count.index]}"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = ["${aws_security_group.tasks.id}"]
    subnets          = ["${aws_subnet.private.*.id}"]
  }

  load_balancer {
    container_name = "${var.task_names[count.index]}"
    container_port = "${var.container_ports[count.index]}"
    target_group_arn = "${aws_lb_target_group.tasks.arn}"
  }
}

// ECR
resource "aws_ecr_repository" "tasks" {
  name = "${var.ecr_repo_name}"
}

// Build the docker images
resource "null_resource" "build_images" {

  depends_on = ["aws_ecr_repository.tasks"]

  count = "${length(var.task_names)}"

  provisioner "local-exec" {
    command = "cd ${path.root}/ecs/docker && docker build -t ${var.task_names[count.index]}:${var.task_names[count.index]} -f ${var.task_names[count.index]} ."
  }
}

// Build the provisioner files
data template_file "tasks" {
  count = "${length(var.task_names)}"

  template = "${file("${path.root}/ecs/ecr/upload_tasks.sh")}"

  vars = {
    region = "${var.aws_region}"
    profile = "${var.profile}"
    image_tag = "${var.task_names[count.index]}"
    repository_url = "${aws_ecr_repository.tasks.repository_url}"
  }
}
resource "local_file" "tasks" {
  count = "${length(var.task_names)}"

  depends_on = ["data.template_file.tasks"]
  content = "${data.template_file.tasks.*.rendered[count.index]}"
  filename = "${path.root}/ecs/ecr/${count.index}.sh"
}

// Upload the images to ECR
resource "null_resource" "upload_images" {
  count = "${length(var.task_names)}"
  depends_on = [
    "null_resource.build_images",
    "local_file.tasks"]

  provisioner "local-exec" {
    command = "${path.root}/ecs/ecr/${count.index}.sh"
  }
}

// Variable outputs for the API module
output "task_names" {
  value = "${var.task_names}"
}
output "container_ports" {
  value = "${var.container_ports}"
}

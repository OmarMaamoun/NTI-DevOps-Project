###################################################
# IAM Roles (cluster & node)
###################################################

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "eks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

###################################################
# Security Groups
###################################################


resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 9443
    to_port     = 9443
    protocol    = "tcp"
    security_groups = [aws_security_group.eks_nodes_sg.id]
    description = "Allow EKS CP to LBC Webhook"
  }

  tags = {
    Name = "${var.environment}-eks-cluster-sg"
  }
}


resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-nodes-sg"
  description = "EKS nodes security group"
  vpc_id      = var.vpc_id

  # Allow nodes to talk to each other
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-eks-nodes-sg"
  }
}


resource "aws_security_group" "elb_sg" {
  name        = "elb-sg"
  description = "Security group for the EKS LB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-elb-sg"
  }
}

# the ALB (for logging)
resource "aws_lb" "eks_lb" {
  name               = "eks-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_sg.id]
  subnets            = var.eks_public_subnets
  
  access_logs {
    bucket  = var.bucket_name
    prefix  = "elb-logs"
    enabled = true
  }
   tags = {
    Name = "${var.environment}-eks-alb"
  }
}


resource "aws_lb_listener" "eks_listener" {
  load_balancer_arn = aws_lb.eks_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
   
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks_tg.arn
  }
}


resource "aws_lb_target_group" "eks_tg" {
   name        = "eks-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  tags = {
    "elbv2.k8s.aws/targetGroupBinding" = "shared"
  }
}

###################################################
# Security Group Rules (to avoid cycle)
###################################################

# Allow Cluster to talk to Node Kubelets (Port 10250)
resource "aws_security_group_rule" "nodes_ingress_from_cluster" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  description              = "Allow EKS control plane to Kubelet"
}

#  Allow Nodes to talk to Cluster API (Port 443)
resource "aws_security_group_rule" "cluster_ingress_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  description              = "Allow nodes to EKS control plane"
}


###################################################
# EKS Cluster
###################################################

# UPDATED: Added private/public endpoint access
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.33"

  vpc_config {
    subnet_ids              = var.eks_private_subnets
    security_group_ids      = [aws_security_group.eks_cluster_sg.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

###################################################
# Launch Template (no custom AMI or user_data)
###################################################
resource "aws_launch_template" "eks_node_template" {
  name_prefix   = "eks-node-"
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.eks_nodes_sg.id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "eks-node"
    }
  }
}

###################################################
# EKS Node Group (Amazon Linux 2023 - managed bootstrap)
###################################################


resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.eks_private_subnets
  ami_type        = "AL2023_x86_64_STANDARD"


  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  launch_template {
    id      = aws_launch_template.eks_node_template.id
    version = aws_launch_template.eks_node_template.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_policy,
    aws_iam_role_policy_attachment.eks_ecr_readonly,
    aws_iam_role_policy_attachment.eks_cni_policy
  ]
}

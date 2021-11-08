# aws-eks.tf
# taken directly from
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}



resource "aws_eks_cluster" "example" {
  name                      = var.cluster_name

  # ... other configuration ...
  role_arn = aws_iam_role.example.arn
  enabled_cluster_log_types = ["api", "audit"]

  vpc_config {
    subnet_ids = [aws_subnet.example1.id, aws_subnet.example2.id, aws_subnet.example3.id]
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.example-AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.example
  ]
}

resource "aws_cloudwatch_log_group" "example" {
  # The log group name format is /aws/eks/<cluster-name>/cluster
  # Reference: https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7

  # ... potentially other configuration ...
}
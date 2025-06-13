variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "aws-event-driven-pipeline"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "playground"
}

variable "worker_instance_type" {
  description = "EC2 instance type for worker."
  type        = string
  default     = "t3.micro"
}

variable "worker_autoterminate_minutes" {
  description = "Minutes after which worker EC2 should auto-terminate."
  type        = number
  default     = 5
}

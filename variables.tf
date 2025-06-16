variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aws-event-driven-pipeline"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "playground"
}

variable "worker_instance_type" {
  description = "EC2 instance type for the worker"
  type        = string
  default     = "t3.micro"
}

variable "worker_autoterminate_minutes" {
  description = "Number of minutes of idle time before EC2 instance terminates"
  type        = number
  default     = 5
}

variable "eventbridge_schedule_expression" {
  description = "Schedule expression for the EventBridge rule"
  type        = string
  default     = "rate(1 minute)"
}

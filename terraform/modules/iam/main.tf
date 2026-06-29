data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# App EC2 Role
resource "aws_iam_role" "app_ec2" {
  name               = "${var.project_name}-app-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${var.project_name}-app-ec2-role"
  }
}

data "aws_iam_policy_document" "app_ec2_policy" {
  # Secrets Manager
  statement {
    sid     = "SecretsManagerAccess"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:pyforum/*"
    ]
  }

  # S3 object access
  statement {
    sid = "S3ObjectAccess"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
  }

  # S3 bucket listing
  statement {
    sid       = "S3BucketList"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.s3_bucket_name}"]
  }

  # ECR auth token
  statement {
    sid       = "ECRAuthToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # ECR image pull
  statement {
    sid = "ECRImagePull"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability"
    ]
    resources = [var.ecr_repo_arn]
  }
}

resource "aws_iam_role_policy" "app_ec2" {
  name   = "${var.project_name}-app-ec2-policy"
  role   = aws_iam_role.app_ec2.id
  policy = data.aws_iam_policy_document.app_ec2_policy.json
}

resource "aws_iam_instance_profile" "app_ec2" {
  name = "${var.project_name}-app-ec2-profile"
  role = aws_iam_role.app_ec2.name

  tags = {
    Name = "${var.project_name}-app-ec2-profile"
  }
}

# Jenkins EC2 Role
resource "aws_iam_role" "jenkins_ec2" {
  name               = "${var.project_name}-jenkins-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${var.project_name}-jenkins-ec2-role"
  }
}

data "aws_iam_policy_document" "jenkins_ec2_policy" {
  # ECR auth token
  statement {
    sid       = "ECRAuthToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  # ECR full push+pull
  statement {
    sid = "ECRFullAccess"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages"
    ]
    resources = [var.ecr_repo_arn]
  }

  # Secrets Manager
  statement {
    sid     = "SecretsManagerAccess"
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:pyforum/*"
    ]
  }
}

resource "aws_iam_role_policy" "jenkins_ec2" {
  name   = "${var.project_name}-jenkins-ec2-policy"
  role   = aws_iam_role.jenkins_ec2.id
  policy = data.aws_iam_policy_document.jenkins_ec2_policy.json
}

resource "aws_iam_instance_profile" "jenkins_ec2" {
  name = "${var.project_name}-jenkins-ec2-profile"
  role = aws_iam_role.jenkins_ec2.name

  tags = {
    Name = "${var.project_name}-jenkins-ec2-profile"
  }
}

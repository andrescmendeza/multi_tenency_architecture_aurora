# -----------------------------------------
# The ECR Repository
# -----------------------------------------

# Base Image
data "aws_ecr_repository" "tms_base_image" {
  name = var.ecr_tms_base_image
}

resource "aws_ecr_repository" "ecr-repo" {
  name = "feature-tms-api"

  tags = {
    Environment = "feature"
  }
}

resource "aws_ecr_lifecycle_policy" "tms" {
  repository = aws_ecr_repository.ecr-repo.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 14 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF

}
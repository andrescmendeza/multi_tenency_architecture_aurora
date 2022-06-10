# -----------------------------------------
# TMS UI - Amplify
# -----------------------------------------

#Get the code commit repository

data "aws_codecommit_repository" "repository" {
  repository_name = "feature-tms-ui"
}

#Policy document specifying what service can assume the role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["amplify.amazonaws.com"]
    }
  }
}
#IAM role providing read-only access to CodeCommit
resource "aws_iam_role" "amplify-codecommit" {
  name                = "feature-AmplifyCodeCommit"
  assume_role_policy  = join("", data.aws_iam_policy_document.assume_role.*.json)
  managed_policy_arns = ["arn:aws:iam::aws:policy/AWSCodeCommitReadOnly"]
}

#Amplify Application
resource "aws_amplify_app" "tms-ui-app" {
  name                     = "feature-tms-ui"
  repository               = data.aws_codecommit_repository.repository.clone_url_http
  iam_service_role_arn     = aws_iam_role.amplify-codecommit.arn
  enable_branch_auto_build = true
  #AMplify buildspec definition
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            # Unit test
            #- npm run test -- -u
        build:
          commands:
            # Build UI
            - npm install
            - npm run build
      artifacts:
        baseDirectory: dist
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT
  # The default rewrites and redirects added by the Amplify Console.
  custom_rule {
    source = "/<*>"
    status = "404"
    target = "/index.html"
  }
  custom_rule {
    source = "</^[^.]+$|\\.(?!(css|gif|ico|jpg|js|png|txt|svg|woff|woff2|otf|ttf|map|json)$)([^.]+$)/>"
    status = "200"
    target = "/index.html"
  }

  # All Brnaches environment variables
  environment_variables = {
    APP_HOST        = "https://feature-tms-api.${var.domain}"
    BASE_URL        = "https://feature-tms.${var.domain}"
    VUE_APP_HTTPS   = "true"
    VUE_APP_TENANT  = "eluma"
    VUE_APP_API_URL = "https://feature-tms-api.${var.domain}/api"
    _LIVE_UPDATES = jsonencode(
      [
        {
          pkg     = "node"
          type    = "nvm"
          version = "16"
        },
      ]
    )
  }
# Patern creation branches
  enable_auto_branch_creation = false
  auto_branch_creation_patterns = [
    "*",
    "*/**",
  ]
}
# Branches connection
resource "aws_amplify_branch" "branch" {
  app_id      = aws_amplify_app.tms-ui-app.id
  branch_name = "feature"
  framework   = "Vue"
  stage       = "PRODUCTION"
}
#Branches domain association

resource "aws_amplify_domain_association" "domain_assoc" {
  app_id      = aws_amplify_app.tms-ui-app.id
  domain_name = var.domain

  sub_domain {
    branch_name = aws_amplify_branch.branch.branch_name
    prefix      = "feature-tms"
  }
}
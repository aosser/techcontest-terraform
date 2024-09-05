resource "aws_codebuild_project" "cicd_terraform_plan" {
  name          = "cicd_terraform_plan"
  description   = "cicd_terraform_plan"
  build_timeout = 90
  service_role  = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_LAMBDA_2GB"
    image                       = "public.ecr.aws/hashicorp/terraform:latest"
    type                        = "LINUX_LAMBDA_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    # environment_variable {
    # }
  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "terraform/app/buildspec_terraform_plan.yml"
    git_clone_depth = 0
  }
}

resource "aws_codebuild_project" "cicd_terraform_apply" {
  name          = "cicd_terraform_apply"
  description   = "cicd_terraform_apply"
  build_timeout = 90
  service_role  = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_LAMBDA_2GB"
    image                       = "public.ecr.aws/hashicorp/terraform:latest"
    type                        = "LINUX_LAMBDA_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    # environment_variable {
    # }
  }
  source {
    type            = "CODEPIPELINE"
    buildspec       = "terraform/app/buildspec_terraform_apply.yml"
    git_clone_depth = 0
  }
}
resource "aws_codepipeline" "terraform_pipeline" {
  name     = "terraform_pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }
  execution_mode = "QUEUED"
  pipeline_type = "V2"
  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      # pull_request {}
      push {
        branches {
          includes = [ "main" ]
        }
        file_paths {
          includes = [ "terraform/app/**" ]
        }
      }
    }
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      namespace        = "SourceVariables"
      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "aosser/techcontest-terraform"
        BranchName       = "main"
        DetectChanges    = "false"
      }
    }
  }

  stage {
    name = "Plan"
    action {
      name             = "Terraform-Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["plan_output"]
      namespace        = "PlanVariables"
      configuration = {
        ProjectName = aws_codebuild_project.cicd_terraform_plan.name
      }
    }
  }

  stage {
    name = "Apply"
    action {
      name             = "Terraform-Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["plan_output"]
      output_artifacts = ["apply_output"]
      namespace        = "ApplyVariables"
      configuration = {
        ProjectName = aws_codebuild_project.cicd_terraform_apply.name
      }
    }
  }

}
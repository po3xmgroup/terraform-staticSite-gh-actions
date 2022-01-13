terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.26.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.1"
    }
  }
  required_version = ">= 1.1.0"

  cloud {
    organization = "3xmgroup"

    workspaces {
      name = "po3xmgroup-staticsite"
    }
  }
}


provider "aws" {
  region = "us-east-1"
}

resource "aws_codepipeline" "codepipeline" {
  name     = "tf-test-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"


  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      region           = "us-east-1"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
      namespace        = "SourceVariables"

      configuration = {
        ConnectionArn        = "arn:aws:codestar-connections:us-east-1:424819937310:connection/8bd6b56e-05ef-4e21-b85e-cfed60d4c798"
        FullRepositoryId     = "po3xmgroup/testS3StaticSite"
        BranchName           = "dev"
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }



  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      region          = "us-east-1"
      owner           = "AWS"
      provider        = "S3"
      input_artifacts = ["SourceArtifact"]
      namespace       = "DeployVariables"
      version         = "1"

      configuration = {
        Extract    = "true"
        BucketName = "s3-static-website-training"
      }
    }
  }
}

resource "aws_codestarconnections_connection" "codepipeline" {
  name          = "example-connection"
  provider_type = "GitHub"
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "s3-static-website-training"
  acl    = "public-read"
  policy = <<EOF
{
  "Id": "bucket_policy_site",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "bucket_policy_site_main",
      "Action": [
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::s3-static-website-training/*",
      "Principal": "*"
    }
  ]
}
EOF
  website {
    index_document = "index.html"
    error_document = "error.html"


  }
  tags = {
    project   = "training"
    createdBy = "pabloOjeda"
  }
}
resource "aws_iam_role" "codepipeline_role" {
  name = "po3xm-test-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.codepipeline_role.id

  policy = templatefile("./policy.json", { aws_codepipeline = "tf-test-pipeline" })

}

resource "aws_securityhub_account" "securityhub" {
  enable_default_standards = false
}

# resource "aws_iam_role" "prowler-scanner-role" {
#   name = "prowler-scanner-assumerole-${var.account_ids[0]}"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       "Action" = "sts:AssumeRole"
#       Principal = {
#         "AWS" = "585853585762"
#       },
#       Condition = {}
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "prowler_scanner_assume_role_attach_policy" {
#   role     = aws_iam_role.prowler-scanner-role.name
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
# }

# resource "aws_iam_role_policy_attachment" "prowler_scanner_ecs_attach_policy" {
#   role     = aws_iam_role.prowler-scanner-role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
# }

resource "aws_iam_role" "prowler" {
  name = "prowler-scanner-scanrole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        "AWS" = "arn:aws:iam::${var.security_account_id}:role/prowler-scanner-assumerole-${var.account_ids[0]}"
      },
      "Action" = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "prowler_securityhub_policy" {
  name = "prowler-securityhub-policy"
  role = aws_iam_role.prowler.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "securityhub:BatchImportFindings",
        "securityhub:GetFindings"
      ]
      Effect = "Allow"
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy" "prowler_custom_policy" {
  name = "prowler-custom-policy"
  role = aws_iam_role.prowler.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "account:Get*",
        "appstream:Describe*",
        "appstream:List*",
        "backup:List*",
        "bedrock:List*",
        "bedrock:Get*",
        "cloudtrail:GetInsightSelectors",
        "codeartifact:List*",
        "codebuild:BatchGet*",
        "codebuild:ListReportGroups",
        "cognito-idp:GetUserPoolMfaConfig",
        "dlm:Get*",
        "drs:Describe*",
        "ds:Get*",
        "ds:Describe*",
        "ds:List*",
        "dynamodb:GetResourcePolicy",
        "ec2:GetEbsEncryptionByDefault",
        "ec2:GetSnapshotBlockPublicAccessState",
        "ec2:GetInstanceMetadataDefaults",
        "ecr:Describe*",
        "ecr:GetRegistryScanningConfiguration",
        "elasticfilesystem:DescribeBackupPolicy",
        "glue:GetConnections",
        "glue:GetSecurityConfiguration*",
        "glue:SearchTables",
        "lambda:GetFunction*",
        "logs:FilterLogEvents",
        "lightsail:GetRelationalDatabases",
        "macie2:GetMacieSession",
        "macie2:GetAutomatedDiscoveryConfiguration",
        "s3:GetAccountPublicAccessBlock",
        "shield:DescribeProtection",
        "shield:GetSubscriptionState",
        "securityhub:BatchImportFindings",
        "securityhub:GetFindings",
        "servicecatalog:Describe*",
        "servicecatalog:List*",
        "ssm:GetDocument",
        "ssm-incidents:List*",
        "support:Describe*",
        "tag:GetTagKeys",
        "wellarchitected:List*"
      ]
      Effect = "Allow"
      Resource = "*"
      Sid = "AllowMoreReadForProwler"
    },
    {
      Effect = "Allow"
      Action = [
        "apigateway:GET"
      ],
      Resource = [
        "arn:aws:apigateway:*::/restapis/*",
        "arn:aws:apigateway:*::/apis/*"
      ]
    }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "prowler_job_function_attach_policy" {
  role     = aws_iam_role.prowler.name
  policy_arn = "arn:aws:iam::aws:policy/job-function/ViewOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "prowler_security_attach_policy" {
  role     = aws_iam_role.prowler.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}


module "prowler" {
  source  = "elasticscale/prowler/aws"
  version = "1.0.4"
  account_ids = var.account_ids
  security_account_id = var.security_account_id
  schedule_expression = "cron(*/45 * * * ? *)"
}
// inspired on https://github.com/sashee/appsync-rds/
resource "random_password" "db_master_pass" {
  length           = 40
  special          = true
  min_special      = 5
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

resource "random_id" "id" {
  byte_length = 8
}

resource "aws_secretsmanager_secret" "db-pass" {
  name = "db-pass-${random_id.id.hex}"
}

resource "aws_secretsmanager_secret_version" "db-pass-val" {
  secret_id = aws_secretsmanager_secret.db-pass.id
  secret_string = jsonencode(
    {
      username = aws_rds_cluster.cluster.master_username
      password = aws_rds_cluster.cluster.master_password
      engine   = "mysql"
      host     = aws_rds_cluster.cluster.endpoint
    }
  )
}

resource "aws_rds_cluster" "cluster" {
  engine               = "aurora-mysql"
  engine_mode          = "serverless"
  database_name        = "mydb"
  master_username      = "admin"
  master_password      = random_password.db_master_pass.result
  enable_http_endpoint = true
  skip_final_snapshot  = true
  scaling_configuration {
    min_capacity = 1
  }
}

resource "terraform_data" "db_setup" {
  triggers_replace = {
    input = filesha1("initial.sql")
  }
  provisioner "local-exec" {
    command = <<-EOF
			while read line; do
				echo "$line"
				aws rds-data execute-statement --resource-arn "$DB_ARN" --database  "$DB_NAME" --secret-arn "$SECRET_ARN" --sql "$line"
			done  < <(awk 'BEGIN{RS=";\n"}{gsub(/\n/,""); if(NF>0) {print $0";"}}' initial.sql)
			EOF
    environment = {
      DB_ARN     = aws_rds_cluster.cluster.arn
      DB_NAME    = aws_rds_cluster.cluster.database_name
      SECRET_ARN = aws_secretsmanager_secret.db-pass.arn
    }
    interpreter = ["bash", "-c"]
  }
}

resource "aws_iam_role" "appsync" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "appsync.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "appsync" {
  statement {
    actions = [
      "rds-data:ExecuteStatement",
    ]
    resources = [
      aws_rds_cluster.cluster.arn,
    ]
  }
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      aws_secretsmanager_secret.db-pass.arn,
    ]
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_role_policy" "appsync" {
  role   = aws_iam_role.appsync.id
  policy = data.aws_iam_policy_document.appsync.json
}

resource "aws_cloudwatch_log_group" "loggroup" {
  name              = "/aws/appsync/apis/${aws_appsync_graphql_api.appsync.id}"
  retention_in_days = 14
}

resource "aws_appsync_graphql_api" "appsync" {
  name                = "appsync_test"
  schema              = file("schema.graphql")
  authentication_type = "API_KEY"
  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.appsync.arn
    field_log_level          = "ALL"
  }
}

resource "aws_appsync_datasource" "rds" {
  api_id           = aws_appsync_graphql_api.appsync.id
  name             = "rds"
  service_role_arn = aws_iam_role.appsync.arn
  type             = "RELATIONAL_DATABASE"
  relational_database_config {
    http_endpoint_config {
      db_cluster_identifier = aws_rds_cluster.cluster.arn
      aws_secret_store_arn  = aws_secretsmanager_secret.db-pass.arn
      database_name         = aws_rds_cluster.cluster.database_name
    }
  }
}

# resolvers
resource "aws_appsync_resolver" "Query_groupById" {
  api_id            = aws_appsync_graphql_api.appsync.id
  type              = "Query"
  field             = "groupById"
  data_source       = aws_appsync_datasource.rds.name
  request_template  = <<EOF
{
	"version": "2018-05-29",
	"statements": [
		"SELECT * FROM UserGroup WHERE id = :ID"
	],
	"variableMap": {
		":ID": $util.toJson($ctx.args.id)
	}
}
EOF
  response_template = <<EOF
#if($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
#set($results=$utils.rds.toJsonObject($ctx.result)[0])
#if($results.isEmpty())
	null
#else
	$utils.toJson($results[0])
#end
EOF
}

resource "aws_appsync_resolver" "Group_users" {
  api_id            = aws_appsync_graphql_api.appsync.id
  type              = "Group"
  field             = "users"
  data_source       = aws_appsync_datasource.rds.name
  request_template  = <<EOF
{
	"version": "2018-05-29",
	"statements": [
		"SELECT * FROM User WHERE groupId = :GROUP_ID"
	],
	"variableMap": {
		":GROUP_ID": $util.toJson($ctx.source.id)
	}
}
EOF
  response_template = <<EOF
#if($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
#set($results=$utils.rds.toJsonObject($ctx.result)[0])
$utils.toJson($results)
EOF
}

resource "aws_appsync_resolver" "User_group" {
  api_id            = aws_appsync_graphql_api.appsync.id
  type              = "User"
  field             = "group"
  data_source       = aws_appsync_datasource.rds.name
  request_template  = <<EOF
{
	"version": "2018-05-29",
	"statements": [
		"SELECT * FROM UserGroup WHERE id = :GROUP_ID"
	],
	"variableMap": {
		":GROUP_ID": $util.toJson($ctx.source.groupId)
	}
}
EOF
  response_template = <<EOF
#if($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
#set($results=$utils.rds.toJsonObject($ctx.result)[0])
#if($results.isEmpty())
	null
#else
	$utils.toJson($results[0])
#end
EOF
}

resource "aws_appsync_resolver" "Mutation_addUser" {
  api_id            = aws_appsync_graphql_api.appsync.id
  type              = "Mutation"
  field             = "addUser"
  data_source       = aws_appsync_datasource.rds.name
  request_template  = <<EOF
#set($id=$utils.autoId())
{
	"version": "2018-05-29",
	"statements": [
		"insert into User VALUES (:ID, :NAME, :GROUP_ID)",
		"SELECT * FROM User WHERE id = :ID"
	],
	"variableMap": {
		":ID": $util.toJson($id),
		":NAME": $util.toJson($ctx.args.name.replace("'", "''").replace("\", "\\")),
		":GROUP_ID": $util.toJson($ctx.args.groupId.replace("'", "''").replace("\", "\\"))
	}
}
EOF
  response_template = <<EOF
#if($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
#set($results=$utils.rds.toJsonObject($ctx.result)[1])
#if($results.isEmpty())
	null
#else
	$utils.toJson($results[0])
#end
EOF
}

resource "aws_appsync_resolver" "Mutation_addGroup" {
  api_id            = aws_appsync_graphql_api.appsync.id
  type              = "Mutation"
  field             = "addGroup"
  data_source       = aws_appsync_datasource.rds.name
  request_template  = <<EOF
#set($id=$utils.autoId())
{
	"version": "2018-05-29",
	"statements": [
		"insert into UserGroup VALUES (:ID, :NAME)",
		"SELECT * FROM UserGroup WHERE id = :ID"
	],
	"variableMap": {
		":ID": $util.toJson($id),
		":NAME": $util.toJson($ctx.args.name.replace("'", "''").replace("\", "\\")),
	}
}
EOF
  response_template = <<EOF
#if($ctx.error)
	$util.error($ctx.error.message, $ctx.error.type)
#end
#set($results=$utils.rds.toJsonObject($ctx.result)[1])
#if($results.isEmpty())
	null
#else
	$utils.toJson($results[0])
#end
EOF
}

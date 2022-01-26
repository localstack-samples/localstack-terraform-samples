# cognito authorizer
resource "aws_cognito_user_pool" "pool" {
  name = "cognito-demo-pool"
}

resource "aws_cognito_user_pool_client" "client" {
  name = "client"

  user_pool_id = aws_cognito_user_pool.pool.id

  generate_secret = true

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH"
  ]
}

# resource "null_resource" "cognito_user" {

#   triggers = {
#     user_pool_id = aws_cognito_user_pool.pool.id
#   }

#   provisioner "local-exec" {
#     command = "aws cognito-idp admin-create-user --user-pool-id ${aws_cognito_user_pool.pool.id} --username myuser"
#   }
# }

output "pool_arn" {
  value = aws_cognito_user_pool.pool.arn
}

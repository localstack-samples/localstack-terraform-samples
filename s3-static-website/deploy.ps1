# This script is used to deploy the static website to LocalStack S3 bucket.
# It uses the lstk CLI to start the LocalStack container, create an S3 bucket, upload the website files to the bucket, and configure the bucket as a static website.

param(
    [switch]$InstallDependencies,
    [switch]$Deploy,
    [switch]$Start,
    [switch]$Stop,
    [switch]$Logs
)

$env:AWS_ACCESS_KEY_ID = "test"
$env:AWS_SECRET_ACCESS_KEY = "test"
$env:AWS_DEFAULT_REGION = "us-east-1"

function Deploy-Website {
    param(
        [switch]$InstallDependencies,
        [switch]$Deploy,
        [switch]$Start,
        [switch]$Stop,
            [switch]$Logs
    )

    if ($InstallDependencies) {
        if (-not (Get-Command -Name 'lstk' -ErrorAction SilentlyContinue)) {
            npm install -g @localstack/lstk
            Write-Host "lstk CLI installed successfully!"
        }
    }

    if ($Start) {
        lstk start
    }

    if ($Deploy) {
        lstk aws s3api create-bucket --bucket testwebsite
        lstk aws s3api put-bucket-policy --bucket testwebsite --policy file://bucket_policy.json
        lstk aws s3 sync ./www/ s3://testwebsite
        lstk aws s3 website s3://testwebsite/ --index-document index.html --error-document error.html
        Write-Host "`n`nWebsite is available at  https://testwebsite.s3-website.localhost.localstack.cloud:4566/"
    }

    if ($Stop) {
        lstk stop
    }
    if ($Logs){
        lstk logs > logs.txt
    }
}

# You can just run all the tasks in one go by calling the function with all the switches set to $true.
#  .\deploy.ps1 -InstallDependencies -Start -Deploy -Logs -Stop
Deploy-Website -InstallDependencies:$InstallDependencies -Deploy:$Deploy -Start:$Start -Stop:$Stop -Logs:$Logs



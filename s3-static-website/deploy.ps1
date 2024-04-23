# This script is used to deploy the static website to LocalStack S3 bucket.
# It uses the LocalStack CLI to start the LocalStack container, wait for it to be ready, create an S3 bucket, upload the website files to the bucket, and configure the bucket as a static website.

param(
    [switch]$InstallDependencies,
    [switch]$Deploy,
    [switch]$Start,
    [switch]$Stop,
    [switch]$Ready,
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
        [switch]$Ready,
        [switch]$Logs
    )

    if ($InstallDependencies) {
        if (-not (Get-Command -Name 'localstack' -ErrorAction SilentlyContinue)) {
            pip install localstack
            Write-Host "LocalStack CLI installed successfully!"
        }
        if (-not (Get-Command -Name 'awslocal' -ErrorAction SilentlyContinue)) {
            pip install awscli-local
            Write-Host "AWS CLI installed successfully!"
        }
    }

    if ($Start) {
        localstack start -d
    }

    if ($Ready) {
        Write-Host "Waiting on the LocalStack container..."
        localstack wait -t 30
        if ($?) {
            Write-Host "Localstack is ready to use!"
        } else {
            Write-Host "Gave up waiting on LocalStack, exiting."
            exit 1
        }
    }

    if ($Deploy) {
        awslocal s3api create-bucket --bucket testwebsite
        awslocal s3api put-bucket-policy --bucket testwebsite --policy file://bucket_policy.json
        awslocal s3 sync ./www/ s3://testwebsite
        awslocal s3 website s3://testwebsite/ --index-document index.html --error-document error.html
        Write-Host "`n`nWebsite is available at  https://testwebsite.s3-website.localhost.localstack.cloud:4566/"
    }

    if ($Stop) {
        localstack stop
    }
    if ($Logs){
        localstack logs > logs.txt
    }
}

# You can just run all the tasks in one go by calling the function with all the switches set to $true.
#  .\deploy.ps1 -InstallDependencies -Start -Ready -Deploy -Logs -Stop
Deploy-Website -InstallDependencies:$InstallDependencies -Deploy:$Deploy -Start:$Start -Stop:$Stop -Ready:$Ready -Logs:$Logs



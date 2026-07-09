DEPLOY_STEPS := start install deploy
INSTALL_EXTRA = @test -e .venv || ($(PYTHON_BIN) -m venv .venv; source .venv/bin/activate; pip install wheel; pip install psycopg2-binary boto3)
DEPLOY_CMD = $(LSTK) aws s3api create-bucket --bucket testwebsite && $(LSTK) aws s3api put-bucket-policy --bucket testwebsite --policy file://bucket_policy.json && $(LSTK) aws s3 sync ./www/ s3://testwebsite && $(LSTK) aws s3 website s3://testwebsite/ --index-document index.html --error-document error.html && echo -e "\n\nWebsite is available at  https://testwebsite.s3-website.localhost.localstack.cloud:4566/"

include ../common.mk

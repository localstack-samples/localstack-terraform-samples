# Lambda, Kinesis, Firehose, ElasticSearch Integration Example

## Prerequisites

- A valid [LocalStack for AWS license](https://localstack.cloud/pricing). Your license provides a [`LOCALSTACK_AUTH_TOKEN`](https://docs.localstack.cloud/getting-started/auth-token/).
- [Docker](https://docs.docker.com/get-docker/)
- [`lstk` CLI](https://docs.localstack.cloud/aws/tooling/lstk/)
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- `make` and `jq`

## Start LocalStack

```bash
export LOCALSTACK_AUTH_TOKEN=<your-auth-token>
make start
```

## Setup

1. Clone this repo and `cd` into its working directory
2. Install the following tools:
  - [Terraform](https://www.terraform.io/downloads) (v1.1.0 or higher)
3. Start LocalStack in the foreground so you can watch the logs:
   ```
   docker compose up
   ```
4. Open another terminal window and `cd` into the same working directory
5. Create the resource and trigger the invocation of the lambda:
   ```
   ./run.sh
   ```
6. Start a Kibana instance pointing towards the elasticsearch instance:
   ```
   docker run --rm -p 5601:5601 -e "ELASTICSEARCH_HOSTS=http://172.17.0.1:4510" docker.elastic.co/kibana/kibana:7.10.0
   ```
7. Browse the data in your Kibana instance: http://localhost:5601

## API Gateway with AppSync Integration

This project contains an example of an API Gateway with AppSync Integration.

### Requirements


- [ ] Community
- [x] Pro

And the environment variable specifying the endpoint strategy `GRAPHQL_ENDPOINT_STRATEGY=domain`.

More about it [here](https://docs.localstack.cloud/user-guide/aws/appsync/#graphql-endpoints)

### Run

Start LocalStack with a specific endpoint configuration:

```bash
LOCALSTACK_GRAPHQL_ENDPOINT_STRATEGY=domain lstk start
```

```bash
./run.sh
```

## Notes

Use `tfswitch` or `tfenv` to install the required provider version

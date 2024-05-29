# API Gateway MOCK integration

### Requirements

- [x] Community
- [ ] Pro

## Run

```bash
terraform init; terraform plan; terraform apply -auto-approve
```

## Testing

```
curl http://localhost:4566/restapis/<rest-api-id>/test/_user_request_/test
```

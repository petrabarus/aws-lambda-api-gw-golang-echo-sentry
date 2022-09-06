# aws-lambda-api-gw-golang-echo-sentry
Example debugging using API Gateway, Golang, Echo Adapter, and Sentry

## Building

To build the distributable, execute the command below.

```
make dist
```

It will create a `lambda.zip` in the `dist` directory and then copy to
`deployments/terraform/dist` for deployments.

## Deploying

Please create `terraform.tfvars` in the `deployments/terraform` directory,
and add `sentry_dsn` value with your Sentry DSN value.

After that, execute the command below inside the `deployments/terraform` directory 
to create the infrastructure and deploy.

```
terraform apply
```

It will show the base URL for API Gateway.

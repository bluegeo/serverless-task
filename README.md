# serverless-task
Infrastructure as code for deployment of API Gateway-driven ECS-Fargate managed tasks

## Background
_This library is configured on [aws](https://aws.amazon.com/) with [terraform](https://www.terraform.io/)_There are four general pieces of this library, which include:

There are four general components:

1. AWS and its configuration
2. Terraform and its configuration
3. Integration with a JS library for API integration
4. Management of state

## Amazon Web Services Configuration
The first task is to create an AWS account and to create an IAM user that has credentials to 
manage AWS resources. These tasks are heavily documented.

#### AWS
Set up your AWS credentials (if you haven't already) using the AWS CLI.

**Note: Do not put your AWS credentials in the `.tf` code! Use the aws-cli**

`pip install awscli --upgrade --user`

Add the aws-cli executable to your system path variables using [these instructions](https://docs.aws.amazon.com/cli/latest/userguide/installing.html)

Configure your system aws credentials (creates $HOME/.aws/credentials):

`aws configure`

Follow the prompts as necessary, using your credentials from the AWS account (replacing the values
below with the IAM credentials):

```bash
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-west-2
Default output format [None]: json
```

#### Terraform core infrastructure
First, configure the `terraform.tfvars` file with the application-specific variables. This may include any 
private data or passwords because this file is not committed to the repo. An example file would include at a
minimum:

```hcl
// Note: the app name and environment must not contain spaces or special characters
app_name: "awesomeapp"
environment: "development"
aws_region: "us-west-2"
// AWS CLI profile
profile: "default"
```

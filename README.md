# vpc-minimal

The module will create a VPC with private and public networks as well as a NAT gateway, Internet Gateway, and some basic routing. If the env variable is set to "prod" this will be a multi-AZ configuration with redundant NAT gateways and will use two EIPs.

For AWS provider, set up your AWS environment as outlined in the [terraform docs](https://www.terraform.io/docs/providers/aws/index.html)

To set up a DEV environment for testing in a single AZ, run:

```shell
terraform apply -var 'env=dev' -var 'vpc_name=Some_Name' -var 'vpc_cidr=x.x.x.x/x'
```

For Production:

```shell
terraform apply -var 'env=prod' -var 'vpc_name=Some_Name' -var 'vpc_cidr=x.x.x.x/x'
```
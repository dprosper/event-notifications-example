

## Costs and Requirements

You must have a Pay-as-You-Go account in IBM Cloud&trade; to follow the steps in this repository to create resources. Since the costs for these resources will vary, use the [Cost Estimator](https://cloud.ibm.com/estimator/review) to generate a cost estimate based on your projected usage.

Make sure to delete services when they are no longer required in order to not incur charges in your account.


## Getting Started

1. Clone this repository to your local computer.

```sh
    git clone git@github.com:dprosper/event-notifications-example.git
```

2. Copy or rename the `.env.template` an edit it to add your own values.
```sh
    cp .env.template .env
```

3. Source the `.env` file to read the values into your environment.
```sh
    source .env
```

4. Run Terraform to create and configure the environment.
```sh
    terraform apply
```

5. Login  to IBM Cloud.
```sh
    ibmcloud login -r $TF_VAR_ibmcloud_region -g default --apikey $TF_VAR_ibmcloud_api_key
```

```sh
    ibmcloud ce project create --name $TF_VAR_resources_prefix-project
```

  ```sh
    ibmcloud ce app create --name node-app --src . --str buildpacks --build-context-dir /examples/app-nodejs/ --env-from-secret app-secrets --env-from-secret apply-output
  ```

copy <code/>

  ```sh
    ibmcloud ce secret create --name apply-output --from-env-file .apply.output.env
  ```

  ```sh
    ibmcloud ce app update --name node-app --src . --str buildpacks --build-context-dir /examples/app-nodejs/ --env-from-secret app-secrets --env-from-secret apply-output
  ```

  ```sh
    ibmcloud ce project delete --name $TF_VAR_resources_prefix-project
  ```


## Issues

Please open *issues* here: [New Issue](https://github.com/dprosper/event-notifications-example/issues)

## Related Content

- 

## License

See [License](LICENSE) for license information.
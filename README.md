

## Costs and Requirements

You must have a Pay-as-You-Go account in IBM Cloud&trade; to follow the steps in this repository to create resources. Since the costs for these resources will vary, use the [Cost Estimator](https://cloud.ibm.com/estimator/review) to generate a cost estimate based on your projected usage.

Make sure to delete services when they are no longer required in order to not incur charges in your account.


## Getting Started as the Infrastructure Engineer

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
5. As a result of running the apply, you will receive two email messages and two SMS messages asking you to confirm subscription to two topics. You must confirm the subscriptions for the two emails and the two SMS messages, i.e. a total of four confirmations. 

The Event Notifications and Cloud Object Storage will be created and configured. A new file will be created in the directory called `.apply.output.env` and will be needed when you take the persona of the developer.

## Continue as the Application Developer

1. Login to IBM Cloud with your API Key, yes same key used for the infrastructure engineer, we are keeping things simple here ;-) 
```sh
    ibmcloud login -r $TF_VAR_ibmcloud_region -g default --apikey $TF_VAR_ibmcloud_api_key
```

2. Create a new Code Engine project.
```sh
    ibmcloud ce project create --name $TF_VAR_resources_prefix-project
```

**TEST POINT  #1**: Shortly after having initiated that command, you will receive email and SMS messages notifying you that a new Code Engine project was created in your account.

3. Create a secret called `apply-output` based on the `.apply.output.env` that was created earlier after running the `terraform apply`.
  ```sh
    ibmcloud ce secret create --name apply-output --from-env-file .apply.output.env
  ```

4. Deploy the application, we will use NodeJS (Go and Python are coming soon).
  ```sh
    ibmcloud ce app create --name node-app --src . --str buildpacks --build-context-dir /examples/app-nodejs/ --env-from-secret apply-output
  ```

If you need to update the app later on you can use the following command: 

  ```sh
    ibmcloud ce app update --name node-app --src . --str buildpacks --build-context-dir /examples/app-nodejs/ --env-from-secret apply-output
  ```
4. Access the NodeJS app serves an endpoint called `/custom_notification`, after you receive the URL to use for the application, try accessing that endpoint, i.e. `https://<code-engine-app-url>/custom_notification`. You should get a success message in the browser. 

**TEST POINT  #2**: Shortly after having access that endpoint, you can check the COS bucket that was created and you should find a new folder that contains the payload from the event. 

5. Delete the Code Engine Project. 

  ```sh
    ibmcloud ce project delete --name $TF_VAR_resources_prefix-project
  ```

**TEST POINT  #3**: Shortly after having deleted the project, you will receive email and SMS messages notifying you that a Code Engine project was deleted in your account.


## Wrapping up as the Infrastructure Engineer

1. Run Terraform to delete the environment.
```sh
    terraform delete
```

## Issues

Please open *issues* here: [New Issue](https://github.com/dprosper/event-notifications-example/issues)

## Related Content

- 

## License

See [License](LICENSE) for license information.
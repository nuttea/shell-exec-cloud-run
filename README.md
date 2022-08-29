# shell-exec-cloud-run
Execute a shell command within Cloud Run.

Serverless with Cloud Run is a great solution that we can customize our container images for Cloud Run to use. This is an example where we use a Cloud Run service to run your custom binary tools (ex. Security Report generate with trivy), then upload HTML report to a GCS Bucket and schedule recurring everyday with Cloud Scheduler.

This repository contains sample code for use in conjunction with [the article](https://medium.com/@kolban1/shell-exec-with-cloud-run-fbc6d299f6d4) on
debugging Cloud Run applications by running shell commands within a Cloud Run container.

![Architecture](docs/architecture.png)

## Pre-requisites

1. A GCP user account with editor permission on your project (to run cloud build submit and terraform)

## Steps

1.  Create a WORKDIR for this tutorial.

    ```bash
    mkdir gcp-terraform
    cd gcp-terraform
    export WORKDIR=$(pwd)
    ```

2.  Define variables used in this workshop by exporting Environment variables or edit ```terraform.tfvars``` file. Replace the value of PROJECT_ID with your Project ID.

    Set environment variables

    ```bash
    export REPO_URL="https://github.com/nuttea/shell-exec-cloud-run.git"
    export PROJECT_ID=<YOUR Project ID>
    export REGION="asia-southeast1"

    # if you want to do a manual test with 'make deploy'
    # required bucket permission for default Compute Service Account as well
    export BUCKET="<your-bucket-name>"
    export BUCKET_PATH="reports/"
    ```

3.  Set defaults for the gcloud command-line tool.

    ```bash
    gcloud config set project "${PROJECT_ID}"
    gcloud config set compute/region ${REGION}
    ```

4.  Set up Terraform authentication. Learn more about [GCP terraform authentication here](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication).

    ```bash
    gcloud auth application-default login --no-launch-browser
    ```

5.  Clone the repo.

    ```bash
    git clone "${REPO_URL}"
    cd ${WORKDIR}/shell-exec-cloud-run
    ```

6.  Prepare terraform variables.

    ```bash
    export TF_VAR_project_id=${PROJECT_ID}
    export TF_VAR_region=${REGION}
    ```

7.  Build a container image using Cloud Build

    ```bash
    make build
    ```

8. (Optional) Manually deploy and test call

    ```bash
    make deploy
    make call
    ```

9.  Deploy Cloud Run, Cloud Storage and Cloud Scheduler terraform.

    ```bash
    terraform init
    terraform plan
    terraform apply --auto-approve
    ```

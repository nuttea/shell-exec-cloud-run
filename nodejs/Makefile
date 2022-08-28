PROJECT_ID=$(shell gcloud config get-value core/project)
all:
	@echo "build  - Build the docker image"
	@echo "deploy - Deploy the image to Cloud Run"
	@echo "clean  - Clean resoruces created in this test"
	@echo "call   - Call the Cloud Run service"

deploy:
	gcloud run deploy cloud-run-exec-nodejs \
		--image gcr.io/$(PROJECT_ID)/cloud-run-exec-nodejs \
		--max-instances 1 \
		--cpu 1 \
		--memory 1Gi \
		--platform managed \
		--region asia-southeast1 \
		--no-allow-unauthenticated \
		--update-env-vars BUCKET="nuttee-lab-00-01",BUCKET_PATH="report/"

build:
	gcloud builds submit --tag gcr.io/$(PROJECT_ID)/cloud-run-exec-nodejs

clean:
	-gcloud container images delete gcr.io/$(PROJECT_ID)/cloud-run-exec-nodejs --quiet
	-gcloud run services delete cloud-run-exec-nodejs \
		--platform managed \
		--region asia-southeast1 \
		--quiet

call:
	@echo "Calling Node-JS Cloud Run service"
	@url=$(shell gcloud run services describe cloud-run-exec-nodejs --format='value(status.url)' --region asia-southeast1 --platform managed); \
	token=$(shell gcloud auth print-identity-token); \
	curl --request POST \
  		--header "Authorization: Bearer $$token" \
  		--header "Content-Type: text/plain" \
  		$$url/exec \
  		--data-binary "/home/cloudsdk/run.sh"
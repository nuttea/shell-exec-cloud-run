#!/bin/bash

# Generate a html report
# $ trivy image --format template --template "@contrib/html.tpl" -o report.html golang:1.12-alpine
trivy image --format template --template "@html.tpl" -o report-$(date +"%Y%m%d%H%M").html golang:1.12-alpine

# Upload report to GCS Bucket, env examples BUCKET=nuttee-lab-00-01 , BUCKET_PATH=report/
gsutil cp report-*.html gs://$BUCKET/$BUCKET_PATH
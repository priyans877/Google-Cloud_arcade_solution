#!/bin/bash

echo "Establishing Connection Between Cloud Spanner and BigQuery"

# Predefined values
SPANNER_INSTANCE="ecommerce-instance"  # Replace with the actual Cloud Spanner instance name if different
SPANNER_DATABASE="ecommerce"          # Pre-created Spanner database
SPANNER_TABLE="orders"                # Table in Spanner database
BIGQUERY_DATASET="ecommerce"          # Pre-created BigQuery dataset
BIGQUERY_VIEW="order_history"         # View name in BigQuery

echo "Creating BigQuery connection to Cloud Spanner..."

# Create a BigQuery connection to Cloud Spanner
gcloud bigquery connections create spanner_connection \
    --connection-type="CLOUD_SPANNER" \
    --location="US" \
    --properties="instanceId=${SPANNER_INSTANCE},databaseId=${SPANNER_DATABASE}" \
    --project="$(gcloud config get-value project)"

echo "BigQuery connection created successfully."

# Grant necessary permissions to the BigQuery connection
CONNECTION_ID=$(gcloud bigquery connections describe spanner_connection --location="US" --format="value(name)")
gcloud projects add-iam-policy-binding "$(gcloud config get-value project)" \
    --member="serviceAccount:${CONNECTION_ID}" \
    --role="roles/spanner.databaseReader"

echo "Permissions granted successfully."

# Create a view in BigQuery to query the Cloud Spanner data
echo "Creating a BigQuery view to access Spanner data..."
bq mk --dataset --location=US "${BIGQUERY_DATASET}"

VIEW_QUERY="SELECT * FROM EXTERNAL_QUERY('projects/$(gcloud config get-value project)/locations/US/connections/spanner_connection', 'SELECT * FROM ${SPANNER_TABLE}');"
bq mk --use_legacy_sql=false --view="${VIEW_QUERY}" "${BIGQUERY_DATASET}.${BIGQUERY_VIEW}"

echo "BigQuery view '${BIGQUERY_VIEW}' created successfully in dataset '${BIGQUERY_DATASET}'."

echo "Challenge completed! You can now query your Cloud Spanner data from BigQuery."

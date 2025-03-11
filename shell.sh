#!/bin/bash

# Prompt for finalCsvUrl2 if not already set
read -p "Enter the final CSV URL: " finalCsvUrl2
echo "Download URL2: $finalCsvUrl2"

echo "------------------------API CALL TO GET ACCESS TOKEN--------------------"
#response=$(curl --silent --location 'https://ig.aidtaas.com/mobius-iam-service/v1.0/login' \
#--header 'Content-Type: application/json' \
#--data-raw '{
#    "userName": "test12345@gatestautomation.com",
#    "password": "Gaian@123",
#    "productId": "c2255be4-ddf6-449e-a1e0-b4f7f9a2b636",
#    "requestType": "TENANT"
#}')

response=$(curl --silent --location 'https://ig.aidtaas.com/mobius-iam-service/v1.0/login' \
--header 'Content-Type: application/json' \
--data-raw '{
    "userName": "aidtaas@gaiansolutions.com",
    "password": "Gaian@123",
    "productId": "a25ef856-5b39-4601-92f6-6f49d65bf7b3",
    "requestType": "TENANT"
}')


# Log the full response from the login API for debugging
echo "Login Response: $response"

# Extract the access token
AUTHORIZATION=$(echo "$response" | jq -r '.accessToken')

# Check if the token is valid
if [ "$AUTHORIZATION" == "null" ] || [ -z "$AUTHORIZATION" ]; then
    echo "Error: Failed to obtain a valid access token."
    exit 1
fi

echo "Access Token: $AUTHORIZATION"

# Generate a unique ID
export unique_id=$(uuidgen)
echo "Unique ID: $unique_id"

echo --------------------PI-INGESTION MAPPING----------------------------

# Construct the JSON payload for mapping
json_payload2="{\"tenantId\":\"9b8d0711-46ea-43a7-8c8c-cfa736e622ac\",\"configName\":\"${unique_id}\",\"configDescription\":\"Automation Testing Schema\",\"entityId\":\"67d0324d0adca51bf8909c36\",\"entityTenantId\":\"9b8d0711-46ea-43a7-8c8c-cfa736e622ac\",\"fileType\":\"JSON\",\"mapping\":[{\"autoMap\":false,\"mappings\":{\"checks\":\"checks\",\"commands\":\"commands\",\"description\":\"description\",\"id\":\"id\",\"name\":\"name\",\"severity\":\"severity\"},\"sourceEntityId\":\"${finalCsvUrl2}\",\"destinationEntityId\":\"67d0324d0adca51bf8909c36\"}]}"

echo "Generated JSON payload for mapping request:"
echo $json_payload2

# Send the request to create a mapping configuration
mappingconfiresponse2=$(curl --location --request POST 'https://ig.aidtaas.com/pi-ingestion-service-dbaas/v1.0/mappingConfigs' \
--header "Authorization: Bearer $AUTHORIZATION" \
--header 'Content-Type: application/json' \
--data-raw "$json_payload2")

# Output the response body for debugging
echo "Mapping Configuration Response: $mappingconfiresponse2"

# Extract the mapping ID from the response (Check if it exists)
export mappingid2=$(echo "$mappingconfiresponse2" | jq -r '.id')

# If mapping ID is null, print an error and exit
if [ "$mappingid2" == "null" ]; then
  echo "Error: Mapping ID is null. The mapping configuration request failed."
  exit 1
fi

echo "Mapping ID2: $mappingid2"

echo --------------------PI-INGESTION JOB TO EXPORT----------------------------

# Retry logic for the job export request
max_retries=6  # Limit retries to avoid infinite loops
retries=0
delay=10  # Delay between retries in seconds
httpStatus=0

while [ "$httpStatus" != 200 ] && [ $retries -lt $max_retries ]; do
  json_payload_2="{\"universe\":\"66aa30f77daee22fb1f1d214\",\"name\":\"${mappingid2}_$((retries + 1))\",\"description\":\"mapping for XML_TI testing\",\"jobType\":\"ONE_TIME\",\"fileType\":\"JSON\",\"parallelism\":4,\"jarVersion\":\"12.1.5\",\"tags\":{\"BLUE\":[\"qwertyui\"]},\"publish\":false,\"reactive\":false,\"thumbnail\":[\"thumbnail1\",\"thumbnail\"],\"mappingId\":\"${mappingid2}\",\"source\":{\"sourceType\":\"FILE\",\"file\":\"file\",\"kafkaProps\":null,\"mqttProps\":null},\"persist\":true,\"timeZone\":\"Asia/Kolkata\",\"vaultPath\":\"clientTidbCredentials-222\"}"

  echo "Generated JSON payload for job request:"
  echo $json_payload_2

  # Send the request to trigger the job
  #response=$(curl --silent --show-error --write-out "HTTPSTATUS:%{http_code}" \
  #--location --request POST 'https://ig.aidtaas.com/pi-ingestion-service-dbaas/v1.0/jobs?source=CSV&sinks=TI' \
  #--header 'tenantId: 9b8d0711-46ea-43a7-8c8c-cfa736e622ac' \
  #--header 'Content-Type: application/json' \
  #--header "Authorization: Bearer $AUTHORIZATION" \
  #--data-raw "$json_payload_2")
  
  response=$(curl --silent --show-error --write-out "HTTPSTATUS:%{http_code}" \
  --location --request POST 'https://ig.aidtaas.com/pi-ingestion-service-dbaas/v1.0/jobs?source=JSON&sinks=TI' \
  --header 'tenantId: 9b8d0711-46ea-43a7-8c8c-cfa736e622ac' \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $AUTHORIZATION" \
  --data-raw "$json_payload_2")


  # Extract the status code and body
  http_body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
  http_status=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

  echo "Response Body: $http_body"
  echo "Response Status: $http_status"

  httpStatus=$http_status

  # Handle failure if status is not 200
  if [ "$httpStatus" != 200 ]; then
    errorMessage=$(echo "$response" | jq -r '.errorMessage')
    echo "Job failed with error: $errorMessage"
    echo "Retrying in $delay seconds... ($((retries+1))/$max_retries)"
    sleep $delay
    retries=$((retries+1))
  else
    echo "Job successfully triggered!"
    break
  fi
done

# Final job status check
if [ "$httpStatus" != "200" ]; then
  echo "Failed to trigger the job after $max_retries attempts."
else
  echo "Job triggered successfully after $retries retries."
fi

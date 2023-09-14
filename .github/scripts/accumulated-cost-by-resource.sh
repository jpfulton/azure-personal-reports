#!/usr/bin/env bash

OUTPUT="";
COST_REPORTS_DIR="./cost-reports";

echo "Fetching resource groups...";
RESOURCE_GROUPS=( $(az group list --query "[].name" --output tsv ) );

for rg in ${RESOURCE_GROUPS[@]}; do
  echo "Fetching resources for group ${rg}...";
  RESOURCES_IDS=( $(az resource list --resource-group $rg --query "[].id" --output tsv) );

  RG_DIR="${COST_REPORTS_DIR}/${rg}";
  mkdir -p $RG_DIR;

  for id in ${RESOURCES_IDS[@]}; do
    RESOURCE_NAME=$(echo $id | rev | cut -d "/" -f 1 | rev);
    OUTPUT_FILE_NAME="${RG_DIR}/${RESOURCE_NAME}.md";

    echo "Building cost report for ${RESOURCE_NAME} in group ${rg}...";
    OUTPUT=$(azure-cost accumulatedCost --filter ResourceId=$id --output Markdown);

    if [ $? -eq 0 ]; 
      then
        echo "Writing accumulated cost report for ${RESOURCE_NAME} in group ${rg}.";
        echo "$OUTPUT" > $OUTPUT_FILE_NAME; 
      else
        echo "Error running accumulated cost report for ${RESOURCE_NAME} in group: ${rg}.";
    fi
  done

done
#!/usr/bin/env bash

COST_REPORTS_DIR="./cost-reports";

RESOURCE_GROUPS=( $(az group list --query "[].name" --output tsv ) );

for rg in ${RESOURCE_GROUPS[@]}; do
  RESOURCES_IDS=( $(az resource list --resource-group $rg --query "[].id" --output tsv) );

  RG_DIR="${COST_REPORTS_DIR}/${rg}";
  mkdir -p $RG_DIR;

  for id in ${RESOURCES_IDS[@]}; do
    RESOURCE_NAME=$(echo $id | rev | cut -d "/" -f 1 | rev);
    OUTPUT_FILE_NAME="${RG_DIR}/${RESOURCE_NAME}.md";

    #echo $OUTPUT_FILE_NAME;

    OUTPUT=$(azure-cost accumulatedCost --filter ResourceId=$id --output Markdown);
    if [ $? -eq 0 ]; then echo "$OUTPUT" > ${RG_DIR}/${name}.md; fi
  done

done
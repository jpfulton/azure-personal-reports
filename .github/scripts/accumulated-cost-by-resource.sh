#!/usr/bin/env bash

OUTPUT="";
COST_REPORTS_DIR="./cost-reports";

SUMMARY_FILE="${COST_REPORTS_DIR}/README.md";

# Pre-filter some cost-less resource types and sort by resource name
JMES_QUERY="
sort_by(
  [?
    type != 'Microsoft.Compute/sshPublicKeys' &&
    type != 'Microsoft.Compute/virtualMachines/extensions' &&
    type != 'Microsoft.Insights/activityLogAlerts' &&
    type != 'Microsoft.Insights/dataCollectionRules' &&
    type != 'Microsoft.Network/networkInterfaces' &&
    type != 'Microsoft.Network/networkSecurityGroups' &&
    type != 'Microsoft.Network/networkWatchers' &&
    type != 'Microsoft.ManagedIdentity/userAssignedIdentities' &&
    type != 'Microsoft.OperationalInsights/workspaces' &&
    type != 'Microsoft.OperationsManagement/solutions' &&
    type != 'Microsoft.Portal/dashboards'
  ].{id: id, name: name},
  &name) | [].id
";

echo "# Resource Costs Index" > $SUMMARY_FILE;
echo "" >> $SUMMARY_FILE;

echo "- [Total Accumulated Costs](./accumulated-cost.md)" >> $SUMMARY_FILE;
echo "- [Total Cost by Resource](./cost-by-resource.md)" >> $SUMMARY_FILE;
echo "- [Total Daily Costs](./daily-costs.md)" >> $SUMMARY_FILE;
echo "" >> $SUMMARY_FILE;

echo "Fetching resource groups...";
RESOURCE_GROUPS=( $(az group list --query "sort_by([].{name: name}, &name)" --output tsv ) );

for rg in ${RESOURCE_GROUPS[@]}; do
  echo "## ${rg}" >> $SUMMARY_FILE;
  echo "" >> $SUMMARY_FILE;

  RG_DIR="${COST_REPORTS_DIR}/${rg}";
  mkdir -p $RG_DIR;

  echo "Fetching resources for group ${rg}...";
  #RESOURCES_IDS=( $(az resource list --resource-group $rg --query "$JMES_QUERY" --output tsv) );
  readarray -t RESOURCES_IDS < <(az resource list --resource-group $rg --query "$JMES_QUERY" --output tsv);

  for id in "${RESOURCES_IDS[@]}"; do
    RESOURCE_NAME=$(echo $id | rev | cut -d "/" -f 1 | rev);
    OUTPUT_FILE_NAME="${RG_DIR}/${RESOURCE_NAME}.md";

    echo "Building cost report for ${RESOURCE_NAME} in group ${rg}...";
    OUTPUT=$(azure-cost accumulatedCost --filter "ResourceId=$id" --output Markdown);

    if [ $? -eq 0 ]; 
      then
        echo "- [${RESOURCE_NAME}](./${rg}/${RESOURCE_NAME}.md)" >> $SUMMARY_FILE;

        echo "Writing accumulated cost report for ${RESOURCE_NAME} in group ${rg}.";
        echo "$OUTPUT" > $OUTPUT_FILE_NAME; 
      else
        echo "Error running accumulated cost report for ${RESOURCE_NAME} in group: ${rg}.";
        echo "Resource ID: ${id}";
        echo "---";
    fi
  done

  # if there are "cost-able" resources generate the resouce group level report
  if [ ${#RESOURCES_IDS[@]} -ne 0 ];
    then
      echo "Building resource group level cost report for group ${rg}...";
      OUTPUT=$(azure-cost accumulatedCost --filter "ResourceGroupName=$rg" --output Markdown)
      if [ $? -eq 0 ];
        then
          echo "- [Resource Group Summary](./${rg}/resource-group-summary.md)" >> $SUMMARY_FILE;

          echo "Writing accumulated cost report for ${rg}.";
          echo "$OUTPUT" > ${RG_DIR}/resource-group-summary.md; 
        else
          echo "Error running accumulated cost report for group: ${rg}.";
          echo "---";
      fi
  fi

  echo "" >> $SUMMARY_FILE;
done

echo "" >> $SUMMARY_FILE;
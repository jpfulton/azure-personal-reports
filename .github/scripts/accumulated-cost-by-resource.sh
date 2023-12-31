#!/usr/bin/env bash

if [ "$#" -eq 1 ];
  then

    if [ "$1" == "summary-only" ];
      then
        echo "Only writing summary file. No resource reports will be written.";

        echo "Fetching resource groups...";
        RESOURCE_GROUPS=( $(az group list --query "sort_by([].{name: name}, &name)" --output tsv ) );

        WRITE_SUMMARY=1;
        WRITE_RESOURCE_REPORTS=0;
      else
        echo "Using resource group: $1";
        echo "No summary file will be written.";

        RESOURCE_GROUPS=( "$1" );
        WRITE_SUMMARY=0;
        WRITE_RESOURCE_REPORTS=1;
    fi
  else
    echo "Script requires one argument.";
    exit 1;
fi

OUTPUT="";
COST_REPORTS_DIR="./cost-reports";

if [ $WRITE_SUMMARY -eq 1 ];
  then
    SUMMARY_FILE="${COST_REPORTS_DIR}/README.md";
  else
    SUMMARY_FILE="/dev/null";
fi

# Pre-filter some cost-less resource types and sort by resource name
JMES_QUERY="
sort_by(
  [?
    type != 'microsoft.alertsmanagement/smartDetectorAlertRules' &&
    type != 'Microsoft.Compute/sshPublicKeys' &&
    type != 'Microsoft.Compute/virtualMachines/extensions' &&
    type != 'microsoft.insights/actiongroups' &&
    type != 'Microsoft.Insights/activityLogAlerts' &&
    type != 'microsoft.insights/components' &&
    type != 'Microsoft.Insights/dataCollectionRules' &&
    type != 'Microsoft.Network/networkInterfaces' &&
    type != 'Microsoft.Network/networkSecurityGroups' &&
    type != 'Microsoft.Network/networkWatchers' &&
    type != 'Microsoft.Network/privateDnsZones/virtualNetworkLinks' &&
    type != 'Microsoft.ManagedIdentity/userAssignedIdentities' &&
    type != 'Microsoft.OperationalInsights/workspaces' &&
    type != 'Microsoft.OperationsManagement/solutions' &&
    type != 'Microsoft.Portal/dashboards' &&
    type != 'Microsoft.Web/serverFarms' &&
    type != 'Microsoft.Web/sites/slots'
  ].{id: id, name: name},
  &name) | [].id
";

echo "# Cost Reports Summary" > $SUMMARY_FILE;
echo "" >> $SUMMARY_FILE;

echo "> Generated on: $(date) <br />" >> $SUMMARY_FILE;
echo "> Running $(azure-cost version) <br />" >> $SUMMARY_FILE;
echo "> Resources and resource groups with no costs are omitted from details reports. <br />" >> $SUMMARY_FILE;
echo "> Resources that have been deleted will be included in summary calculations but will not have details reports." >> $SUMMARY_FILE;
echo "" >> $SUMMARY_FILE;

echo "- [Total Accumulated Costs](./accumulated-cost.md)" >> $SUMMARY_FILE;
echo "- [Total Cost by Resource](./cost-by-resource.md)" >> $SUMMARY_FILE;
echo "- [Total Daily Costs](./daily-costs.md)" >> $SUMMARY_FILE;
echo "- [Cost Anomalies by Resource](./anomalies-by-resource.md)" >> $SUMMARY_FILE;
echo "" >> $SUMMARY_FILE;

for rg in ${RESOURCE_GROUPS[@]}; do
  RG_DIR="${COST_REPORTS_DIR}/${rg}";
  mkdir -p $RG_DIR;

  echo "Fetching resources for group ${rg}...";
  readarray -t RESOURCES_IDS < <(az resource list --resource-group $rg --query "$JMES_QUERY" --output tsv);

  # if there are "cost-able" resources generate the resouce group level report
  if [ ${#RESOURCES_IDS[@]} -ne 0 ];
    then
      echo "## ${rg}" >> $SUMMARY_FILE;
      echo "" >> $SUMMARY_FILE;

      echo "- [Resource Group Summary](./${rg}/README.md)" >> $SUMMARY_FILE;

      if [ $WRITE_RESOURCE_REPORTS -eq 1 ];
        then
          echo "Clearing old reports...";
          rm -rf ${RG_DIR}/*;

          echo "Building resource group level cost report for group ${rg}...";
          OUTPUT=$(azure-cost accumulatedCost --filter "ResourceGroupName=$rg" --output Markdown);
          if [ $? -eq 0 ];
            then
              echo "Writing accumulated cost report for ${rg}.";
              echo "$OUTPUT" > ${RG_DIR}/README.md;
            else
              echo "Error running accumulated cost report for group: ${rg}.";
              echo "Error code was: $?";
              echo "---";

              echo "# Azure Cost Overview" > ${RG_DIR}/README.md;
              echo "" >> ${RG_DIR}/README.md;
              echo "> An error occured building the summary report for the ${rg} resource group." >> ${RG_DIR}/README.md;
              echo "> Running $(azure-cost version)" >> ${RG_DIR}/README.md;
              echo "" >> ${RG_DIR}/README.md;
          fi
        fi  
    else
      echo "No 'cost-able' resources found in resource group. Removing directory and moving on...";
      echo "---";

      rm -rf ${RG_DIR};
  fi

  for id in "${RESOURCES_IDS[@]}"; do
    RESOURCE_NAME=$(echo $id | rev | cut -d "/" -f 1 | rev);
    OUTPUT_FILE_NAME="${RG_DIR}/${RESOURCE_NAME}.md";

    echo "- [${RESOURCE_NAME}](./${rg}/${RESOURCE_NAME}.md)" >> $SUMMARY_FILE;

    echo "Building cost report for ${RESOURCE_NAME} in group ${rg}...";
    [ $WRITE_RESOURCE_REPORTS -eq 1 ] && OUTPUT=$(azure-cost accumulatedCost --filter "ResourceId=$id" --output Markdown);

    if [ $WRITE_RESOURCE_REPORTS -eq 1 ] && [ $? -eq 0 ]; 
      then
        [ $WRITE_RESOURCE_REPORTS -eq 1 ] && echo "Writing accumulated cost report for ${RESOURCE_NAME} in group ${rg}.";
        [ $WRITE_RESOURCE_REPORTS -eq 1 ] && echo "$OUTPUT" > $OUTPUT_FILE_NAME; 
      else
        if [ $WRITE_RESOURCE_REPORTS -eq 1 ];
          then
            echo "Error running accumulated cost report for ${RESOURCE_NAME} in group: ${rg}.";
            echo "Resource ID: ${id}";
            echo "Error code was: $?";
            echo "---";

            echo "# Azure Cost Overview" > $OUTPUT_FILE_NAME;
            echo "" >> $OUTPUT_FILE_NAME;
            echo "No costs associated with ${RESOURCE_NAME}" >> $OUTPUT_FILE_NAME;
            echo "" >> $OUTPUT_FILE_NAME;
        fi
    fi
  done

  echo "" >> $SUMMARY_FILE;
done

echo "" >> $SUMMARY_FILE;
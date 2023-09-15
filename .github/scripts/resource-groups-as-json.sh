#!/usr/bin/env bash

#RESOURCE_GROUPS=( $(az group list --query "sort_by([].{name: name}, &name)" --output tsv ) );
readarray -t RESOURCE_GROUPS < <(az group list --query "sort_by([].{name: name}, &name)" --output tsv);

echo "[";

for rg in ${RESOURCE_GROUPS[@]}; do

  echo "  \"${rg}\",";

done

echo "]";
echo;
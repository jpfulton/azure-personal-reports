#!/usr/bin/env bash

#RESOURCE_GROUPS=( $(az group list --query "sort_by([].{name: name}, &name)" --output tsv ) );
readarray -t RESOURCE_GROUPS < <(az group list --query "sort_by([].{name: name}, &name)" --output tsv);

echo "{";
echo "\"group\":";
echo "[";

for index in ${!RESOURCE_GROUPS[@]}; do

  echo -n "\"${RESOURCE_GROUPS[$index]}\"";

  if [ "$(($index + 1))" -ne "${#RESOURCE_GROUPS[@]}" ];
    then
      echo ",";
  fi

done

echo "";
echo "]";
echo "}";

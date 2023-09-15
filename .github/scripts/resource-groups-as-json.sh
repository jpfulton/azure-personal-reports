#!/usr/bin/env bash

#RESOURCE_GROUPS=( $(az group list --query "sort_by([].{name: name}, &name)" --output tsv ) );
readarray -t RESOURCE_GROUPS < <(az group list --query "sort_by([].{name: name}, &name)" --output tsv);

echo -n "{";
echo -n "\"group\":";
echo -n "[";

for index in ${!RESOURCE_GROUPS[@]}; do

  echo -n "\"${RESOURCE_GROUPS[$index]}\"";

  if [ "$(($index + 1))" -ne "${#RESOURCE_GROUPS[@]}" ];
    then
      echo -n ",";
  fi

done

echo -n "]";
echo -n "}";

#!/bin/bash
set -m

/entrypoint.sh couchbase-server &

sleep 15

# Setup index and memory quota
curl -v -X POST http://127.0.0.1:8091/pools/default -d memoryQuota=1024 -d indexMemoryQuota=512

# Setup services
curl -v http://127.0.0.1:8091/node/controller/setupServices -d services=kv%2Cn1ql%2Cindex

# Setup credentials
curl -v http://127.0.0.1:8091/settings/web -d port=8091 -d username=$CLUSTER_CUSTOM_USERNAME -d password=$CLUSTER_CUSTOM_PASSWORD

# Setup Memory Optimized Indexes
# curl -i -u $CLUSTER_CUSTOM_USERNAME:$CLUSTER_CUSTOM_PASSWORD -X POST http://127.0.0.1:8091/settings/indexes -d 'storageMode=memory_optimized'


if [[ "$HOSTNAME" == *-0 ]]; then
  TYPE="MASTER"
else
  TYPE="WORKER"
fi

echo "Type: $TYPE"

if [ "$TYPE" = "WORKER" ]; then
  sleep 15

  IP=$(hostname -i)
  echo "Server-Add: ${COUCHBASE_MASTER}:8091"
  couchbase-cli server-add --cluster=$COUCHBASE_MASTER:8091 --user=$CLUSTER_CUSTOM_USERNAME --password=$CLUSTER_CUSTOM_PASSWORD --server-add=$IP --server-add-username=$CLUSTER_CUSTOM_USERNAME --server-add-password=$CLUSTER_CUSTOM_PASSWORD --services data,index,query

  echo "Auto Rebalance: $AUTO_REBALANCE"
  if [ "$AUTO_REBALANCE" = "true" ]; then
    couchbase-cli rebalance --cluster=$COUCHBASE_MASTER:8091 --user=$CLUSTER_CUSTOM_USERNAME --password=$CLUSTER_CUSTOM_PASSWORD
  fi
fi

fg 1
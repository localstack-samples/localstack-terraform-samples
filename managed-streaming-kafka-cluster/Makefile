TEST_CMD = @$(LSTK) aws kafka list-clusters > cluster_info.json && cat cluster_info.json && if cat cluster_info.json | jq -e '.ClusterInfoList[0].ClusterName == "example" and .ClusterInfoList[0].State == "ACTIVE"' > /dev/null; then echo "Smoke test passed: Cluster name is 'example' and state is 'ACTIVE'."; else echo "Smoke test failed: Cluster name or state is incorrect."; exit 1; fi

include ../common.mk

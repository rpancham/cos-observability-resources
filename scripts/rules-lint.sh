#!/bin/bash -x

# This script checks lint for yaml:
#

CONTAINER_NAME=prometheus-rules-check-yaml-lint
IMAGE=giantswarm/yamllint

docker run -t --name "${CONTAINER_NAME}" \
  -v "$CONFIG_DIR":/workdir/config:z \
  -v "$PROMETHEUS_RULES_DIR":/workdir/rules:z \
  -v "$DASHBOARDS_DIR":/workdir/dashboards:z \
  "${IMAGE}" -c config/yamllint.yaml dashboards rules

if docker logs -f ${CONTAINER_NAME} | grep -q error; then
	docker rm "${CONTAINER_NAME}"
	exit 1
else
	echo "SUCCESS: rules lint"
	docker rm "${CONTAINER_NAME}"
fi
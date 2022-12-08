#!/bin/bash

# This script checks that the rules in the following files are syntactically valid:
#

CONTAINER_NAME=prometheus-rules-check-rhoc-observability

# the temp directory used, within $DIR
# omit the -p parameter to create a temporal directory in the default location
WORK_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'rules')
RULES_FILE="rules.yaml"

# check if tmp dir was created
if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
  echo "Could not create temp dir"
  exit 1
fi

# deletes the temp directory
function cleanup {
  rm -rf "$WORK_DIR"
  echo "Deleted temp working directory $WORK_DIR"
}

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

echo "groups:" > "$WORK_DIR"/"$RULES_FILE"

for f in "${PROMETHEUS_RULES_DIR}"/*.yaml; do
  [[ -e "$f" ]] || break  # handle the case of no *.wav files
  LN=$(grep -n 'groups:' "$f" | cut -d : -f 1 | tail -1)
  LN=$((LN+=1))

  (tail -n "+$LN" "$f" ) >> "$WORK_DIR"/"$RULES_FILE";
done

docker run -t --name "${CONTAINER_NAME}" \
  -v "$WORK_DIR"/"$RULES_FILE":/prometheus/"$RULES_FILE":z \
  -v "$UNIT_TEST_DIR":/prometheus/unit_tests:z \
  --entrypoint=/bin/sh \
  "${IMAGE}" -c 'cd unit_tests && promtool test rules *.yaml'

if docker logs -f ${CONTAINER_NAME} | grep -q FAILED:; then
	docker logs -f ${CONTAINER_NAME}
	docker rm "${CONTAINER_NAME}"
	exit 1
else
	echo "SUCCESS: rules check"
	docker rm "${CONTAINER_NAME}"
fi
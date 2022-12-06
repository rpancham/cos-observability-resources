export UNIT_TEST_DIR ?= $(shell pwd)/resources/prometheus/unit_tests/
export PROMETHEUS_RULES_DIR ?= $(shell pwd)/resources/prometheus/downstream/
export IMAGE ?= quay.io/prometheus/prometheus
export DASHBOARDS_DIR ?= $(shell pwd)/resources/grafana/downstream/
export INDEX_FILE_PATH ?= $(shell pwd)/resources/index.json
export UNIT_TEST_FILES ?= $(shell pwd)/resources/prometheus/unit_tests/
export CRITICAL_SEVERITY="critical"
export WARNING_SEVERITY="warning"
export RHOC_SOPS_REPO_ORG ?= bf2fc6cc711aee1a0c2a

# Checks the prometheus rules in the given rules files
.PHONY: check/rules
check/rules:
	./scripts/rules-check.sh

# Check that each dashboard is valid JSON
.PHONY: validate/dashboards
validate/dashboards:$(shell pwd)
	./scripts/validate-json.sh

# Check that the index file is valid JSON
.PHONY: validate/index
validate/index:$(shell pwd)
	./scripts/validate-index.sh

# Check each alert has a valid unit test
.PHONY: check/unit-tests
check/unit-tests:$(shell pwd)
	./scripts/unit-test-check.sh

# Check each alert has a SOP
.PHONY: alerts/sop_url_exists
alerts/sop_url_exists:$(shell pwd)
	./scripts/validate-sop-url-exists.sh

.PHONY: validate/sop_url_links
validate/sop_url_links:$(shell pwd)
	./scripts/validate-sop-urls.sh

# Run all test targets
.PHONY: run/tests
run/tests: alerts/sop_url_exists validate/sop_url_links validate/dashboards validate/index check/rules check/unit-tests

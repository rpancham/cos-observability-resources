#!/bin/bash

# Checks that the each SOP URL link is valid, i.e can be reached via curl
# and returns a 2* status code. When running in GitHub actions,
# the ACCESS_TOKEN_SECRET variable must be created within the repository to allow
# the curl command to access the private sops repository.

# The ACCESS_TOKEN_SECRET is a Personal Access Token associated with your account:
# https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token

declare -A BAD_SOP_LINKS
RULE_FILES="${PROMETHEUS_RULE_FILE##*/} ${PROMETHEUS_DEVELOPER_RULE_FILE##*/} ${KAFKA_SLO_RULES##*/}"

function check(){
	if [ -z "${ACCESS_TOKEN_SECRET}" ]; then
		"The ACCESS_TOKEN_SECRET variable is empty or incorrect. Please set this variable to execute this check. E.g: export ACCESS_TOKEN_SECRET=<your-access-token>"
		exit 1
	fi

	echo "Validating the SOP URL for alerts in the following files: "$RULE_FILES" ..."

	readarray ALL_SOPS < <(docker run --rm -v "${PROMETHEUS_RULES_DIR}":/workdir:z mikefarah/yq -N e '.spec.groups[]
	| select(.name != "deadmanssnitch")
	| select(.name != "rule-evaluation")
	| .rules[].annotations
	| select(length!=0)
	| .sop_url ' "${PROMETHEUS_RULE_FILE##*/}" "${PROMETHEUS_DEVELOPER_RULE_FILE##*/}" "${KAFKA_SLO_RULES##*/}" | sort -u)

	for SOP in "${ALL_SOPS[@]}"; do
		STATUS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://${ACCESS_TOKEN_SECRET}@raw.githubusercontent.com/$KAS_SOPS_REPO_ORG/kas-sre-sops/main/sops/alerts/${SOP##*/})
		if [[ "$STATUS_RESPONSE" != "2"* ]]; then
		    echo
			echo " Checking: ${SOP##*/} Status Code: $STATUS_RESPONSE"
			BAD_SOP_LINKS[$SOP]=$STATUS_RESPONSE
		else
			echo " Checking: ${SOP##*/} Status Code: $STATUS_RESPONSE"
			echo
		fi
	done

	if  [ ${#BAD_SOP_LINKS[@]} -gt 0 ]; then
		echo "The following SOP URL(s) are invalid, in the wrong folder, or could not be reached:"
		for k in "${!BAD_SOP_LINKS[@]}"; do
			printf "SOP URL Link: $k\nStatus Code: ${BAD_SOP_LINKS[$k]}\n"
		done
		exit 1
	else
		echo
		echo -e " SUCCESS: All SOP URL links are valid"
	fi
}

check

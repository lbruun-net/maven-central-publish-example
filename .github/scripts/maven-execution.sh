#!/bin/bash
#
#  Execute Maven in a GitHub workflow.
#  The POM is expected to use the "Maven CI Friendly" paradigm.
#  (https://maven.apache.org/maven-ci-friendly.html)
#
#
#

set -e

printenv

# Defaults
mvn_phase="verify"
mvn_ci_sha1_short="${GITHUB_SHA::7}"
mvn_ci_revision=""



if [ "GITHUB_REF_TYPE" = "tag" ]; then
  # Does tag look like a SemVer string?
  if [[ "$GITHUB_REF_NAME" =~ ^[0-9]+\.[0-9]+\.[0-9]+.*$ ]]; then
    mvn_phase="deploy"
    mvn_ci_revision="$GITHUB_REF_NAME"
    mvn_ci_sha1_short=""
  else
    # Tagged with something not resembling a SemVer string.
    # This may be a mistake. So we fail!
    echo "Tag \"$GITHUB_REF_NAME\" is not SemVer"
    exit 1
  fi
fi

# Execute maven
mvn \
  --show-version \
  --batch-mode \
  --no-transfer-progress \
  -Dchangelist=  -Dsha1="$mvn_ci_sha1_short"  -Drevision="$mvn_ci_revision" \
  $mvn_phase


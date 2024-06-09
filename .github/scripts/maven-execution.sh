#!/bin/bash
#
#  Execute Maven in a GitHub workflow.
#  The POM is expected to use the "Maven CI Friendly" paradigm.
#  (https://maven.apache.org/maven-ci-friendly.html)
#
#
#

set -e


# Defaults
mvn_phase="verify"
mvn_ci_revision=""
mvn_ci_sha1_short="${GITHUB_SHA::7}"
mvn_ci_changelist=""
mvn_profiles_active=""

# SemVer regular expression:
#  - The tag can optionally start with the 'v' but the 'v' doesn't become part of the
#    Maven version string.
# -  We allow the X.Y.Z version to have a pre-release suffix, e.g. "3.2.0-RC1" but if
#    so we tell Maven that this is a SNAPSHOT release. In other words: tag "3.2.0-RC1" will
#    be published as "3.2.0-RC1-SNAPSHOT" and will therefore go into the snapshot repo,
#    not Maven Central.
#
semver_regex='^v?([0-9]+\.[0-9]+\.[0-9]+(\-[0-9a-zA-Z.]+)*)$'

if [ "$GITHUB_REF_TYPE" = "tag" ]; then
  # Does tag look like a SemVer string?
  if [[ "$GITHUB_REF_NAME" =~ $semver_regex ]]; then
    semver=${BASH_REMATCH[1]}
    semver_prerelease=${BASH_REMATCH[2]}

    mvn_phase="deploy"
    mvn_ci_revision="$semver"
    mvn_ci_sha1_short=""
    mvn_profiles_active="-Prelease-to-central"

    # Test for pre-releases. We turn those into SNAPSHOTs
    if [ ! -z "$semver_prerelease" ]; then
      # Unless "SNAPSHOT" is already the Semver Pre-release string, then..
      if [[ ! "$semver_prerelease" =~ SNAPSHOT$ ]]; then
        mvn_ci_changelist="-SNAPSHOT"  # effectively, this gets appended to the complete Maven version string
      fi
    fi

  else
    # Tagged with something not resembling a SemVer string.
    # This may be a mistake. So we fail!
    echo "Tag \"$GITHUB_REF_NAME\" is not SemVer"
    exit 1
  fi
fi

# Execute maven
set -x
echo "executing mvn"
mvn -X \
  --show-version \
  --batch-mode \
  --no-transfer-progress \
  -DaltReleaseDeploymentRepository=maven-central::https://oss.sonatype.org/service/local/staging/deploy/maven2/ \
  -DaltSnapshotDeploymentRepository=maven-central::https://oss.sonatype.org/content/repositories/snapshots/ \
  -Dchangelist=$mvn_ci_changelist  -Dsha1=$mvn_ci_sha1_short  -Drevision=$mvn_ci_revision  $mvn_profiles_active \
  $mvn_phase


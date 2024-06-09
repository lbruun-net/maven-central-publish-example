#!/bin/bash
#
#  Execute Maven in a GitHub workflow.
#  The POM is expected to use the "Maven CI Friendly" paradigm.
#  (https://maven.apache.org/maven-ci-friendly.html)
#
#  'mvn verify' will be executed by default. However, if executing from a SemVer-like tag
#  then 'mvn deploy' is executed instead.
#

set -e



# Constants
# (Note: Projects which has registered with Sonatype/MavenCentral after February 2021 use
#        "s01.oss.sonatype.org" as the hostname in the URLs below. Change accordingly.)
mvn_central_release_url="https://oss.sonatype.org/service/local/staging/deploy/maven2/"
mvn_central_snapshot_url="https://oss.sonatype.org/content/repositories/snapshots/"


# Defaults
mvn_phase="verify"
mvn_ci_revision=""
mvn_ci_sha1_short="${GITHUB_SHA::7}"
mvn_ci_changelist=""
mvn_profiles_active=""

# SemVer regular expression:
#  - The tag can optionally start with the 'v' but the 'v' doesn't become part of
#    the Maven version string.
# -  We allow the X.Y.Z version to have a pre-release suffix, e.g. "3.2.0-RC1" but if
#    so we tell Maven that this is a SNAPSHOT release. In other words: tag "3.2.0-RC1" will
#    be published as version "3.2.0-RC1-SNAPSHOT" and will therefore go into the OSS Sonatype snapshot repo,
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
#   - 'deployAtEnd':  For multi-module builds this is important. We either want to deploy
#                     all modules or none. (i.e. the deploy should ideally be one atomic action)
mvn \
  --show-version \
  --batch-mode \
  --no-transfer-progress \
  -DinstallAtEnd=true \
  -DdeployAtEnd=true \
  -DaltReleaseDeploymentRepository=maven-central::$mvn_central_release_url \
  -DaltSnapshotDeploymentRepository=maven-central::$mvn_central_snapshot_url \
  -Dchangelist=$mvn_ci_changelist  -Dsha1=$mvn_ci_sha1_short  -Drevision=$mvn_ci_revision  $mvn_profiles_active \
  $mvn_phase


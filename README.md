# Example project: library which gets published to Maven Central


Small and simple example of publishing to Maven Central the "native" way.
It uses modern Maven (since Maven 3.5) where the use of the Maven Release Plugin is no longer
necessary. Instead, a much simpler workflow can be accomplished. 

I call this the "native" way because:

- It works with how Maven works, not against it. There's no special execution 
for publishing your artifact. It is simply a matter of which [Maven phase](https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html#a-build-lifecycle-is-made-up-of-phases)
is executed.

- It works with how Git works, not against it. Since the version number does not exist
  in the source code all we have to do is tag the source code. Bingo!

- It uses the official `setup-java` GitHub Action from GitHub itself, nothing more. 
No weird third-party Action is used.

- It works with how GitHub is intended to work. Your releases are releases both in a Maven
sense but they also appear in the "Releases" section of your project. Thus, you can attached
comments and release notes to your releases, etc.

It also has another benefit: It doesn't encourage publication from developer's own workstation.
I've deliberately removed the `<distributionManagement>` section from POM (it doesn't belong there,
IMO, it belongs in a CI workflow file).

There is a small shell script involved. But its only task is to figure if `mvn verify` or `mvn deploy` 
should be executed. Change it according to your needs and workflow.




## Prerequisites


### POM

- Must be using the [Maven CI Friendly feature](https://maven.apache.org/maven-ci-friendly.html) and the version
element must be `<version>${revision}${sha1}${changelist}</version>`. 
(IMO, all your projects should be using the Maven CI Friendly paradigm)

- Must have a profile named `release-to-central` and one named `ci`. See the example in this repo.


### GitHub Secrets


### GnuPG key and passphrase for signing the artifact

The following GitHub Secrets must exist:

- `MAVEN_CENTRAL_GPG_SECRET_KEY`. GnuPG private key used for signing artifacts published to Maven Central. You can
simply take the output from the `gpg --export-secret-key --armor` command and paste it directly into GitHub UI when
you configure the value for this secret (never mind it has line endings).

- `MAVEN_CENTRAL_GPG_PASSPHRASE`. GnuPG passphrase to accompany your private key.


### Credentials for publishing to Maven Central

You must have a Sonatype Nexus token that allows to publish to Maven Central. It is a string which looks like this:`kFCdW7Su:XKAO3FIWcY731jt3rRDIexfrGVqQLFbjqwOJtiGgEQtP`
(first part before colon we refer to as 'username' and second part after colon as 'password')

The following GitHub Secrets must exist:

- `MAVEN_CENTRAL_USERNAME`. Username part of the Sonatype Nexus token you use to publish to Maven Central. (*)
 
- `MAVEN_CENTRAL_PASSWORD`. Password part of the Sonatype Nexus token you use to publish to Maven Central. (*)

You can use your old-style username/password for the Sonatype Nexus UI instead of token. However, Sonatype has announced that 
old-style username/password will eventually stop working for publishing. You still need your old-style username/password to log 
into the Sonatype Nexus UI, though.


## Releasing

When the project is ready to have a new release, simply go to the GitHub UI and press "Releases". Choose a tag which
complies with [SemVer](https://semver.org/) and press "Publish release". That is all!

If you add a so-called prerelease suffix (in SemVer terminology this means adding a dash+something after the `X.Y.Z`) then
the pipeline will assume you mean a Maven snapshot release and publish to snapshot repository.

You can optionally put a `v` in front of your tags as in `v1.4.8`. It won't become part of the Maven version string. 
Whether you use the `v` or not is up to you. Just be consistent.


Note: Be careful with choosing a tag. Once something is published to Maven Central is can never be retracted. Also, while Git allows
you to delete a tag, the GitHub UI deliberately has no such feature. They've made it hard for you to do such operation .. and
indeed it should be hard!


## How do I know if my flow works? (without publishing)

Simple: Just create a snapshot release, meaning create a release from the GitHub UI with a prerelease suffix. 
This will test that the signing works and that your credentials for Maven Central works. Without creating
a true release.

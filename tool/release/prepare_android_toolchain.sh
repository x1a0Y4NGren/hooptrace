#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
: "${ANDROID_SDK_ROOT:?ANDROID_SDK_ROOT must be set}"
: "${ANDROID_COMPILE_SDK:=36}"
: "${ANDROID_TARGET_SDK:=36}"
: "${ANDROID_BUILD_TOOLS:=36.1.0}"
: "${ANDROID_NDK:=28.2.13676358}"
: "${JAVA_VERSION:=17.0.20+8}"
: "${FLUTTER_FRAMEWORK_REVISION:=00b0c91f06209d9e4a41f71b7a512d6eb3b9c694}"
: "${GRADLE_VERSION:=8.14}"
: "${GRADLE_WRAPPER_SHA256:=7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172}"
: "${GRADLE_DISTRIBUTION_SHA256:=efe9a3d147d948d7528a9887fa35abcf24ca1a43ad06439996490f77569b02d1}"

if [[ "$ANDROID_COMPILE_SDK" != "36" ||
  "$ANDROID_TARGET_SDK" != "36" ||
  "$ANDROID_BUILD_TOOLS" != "36.1.0" ||
  "$ANDROID_NDK" != "28.2.13676358" ||
  "$JAVA_VERSION" != "17.0.20+8" ||
  "$FLUTTER_FRAMEWORK_REVISION" != "00b0c91f06209d9e4a41f71b7a512d6eb3b9c694" ||
  "$GRADLE_VERSION" != "8.14" ||
  "$GRADLE_WRAPPER_SHA256" != "7d3a4ac4de1c32b59bc6a4eb8ecb8e612ccd0cf1ae1e99f66902da64df296172" ||
  "$GRADLE_DISTRIBUTION_SHA256" != "efe9a3d147d948d7528a9887fa35abcf24ca1a43ad06439996490f77569b02d1" ]]; then
  echo "The release Android/Java/Gradle toolchain overrides are not the pinned values." >&2
  exit 2
fi

sdkmanager_bin="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
"$sdkmanager_bin" \
  "platforms;android-$ANDROID_COMPILE_SDK" \
  "build-tools;$ANDROID_BUILD_TOOLS" \
  "ndk;$ANDROID_NDK"

flutter --version --machine | \
  grep -q "\"frameworkVersion\": \"3.41.9\""
flutter --version --machine | \
  grep -q "\"frameworkRevision\": \"$FLUTTER_FRAMEWORK_REVISION\""
java_output="$(java -version 2>&1)"
grep -q "$JAVA_VERSION" <<<"$java_output"
grep -Eq 'Temurin|Eclipse Adoptium' <<<"$java_output"
test -d "$ANDROID_SDK_ROOT/platforms/android-$ANDROID_COMPILE_SDK"
test -d "$ANDROID_SDK_ROOT/build-tools/$ANDROID_BUILD_TOOLS"
test -d "$ANDROID_SDK_ROOT/ndk/$ANDROID_NDK"

grep -Eq "^[[:space:]]*compileSdk[[:space:]]*=[[:space:]]*$ANDROID_COMPILE_SDK[[:space:]]*$" \
  "$repo_root/android/app/build.gradle.kts"
grep -Eq "^[[:space:]]*targetSdk[[:space:]]*=[[:space:]]*$ANDROID_TARGET_SDK[[:space:]]*$" \
  "$repo_root/android/app/build.gradle.kts"

wrapper_properties="$repo_root/android/gradle/wrapper/gradle-wrapper.properties"
wrapper_jar="$repo_root/android/gradle/wrapper/gradle-wrapper.jar"
grep -Fq "distributionUrl=https\\://services.gradle.org/distributions/gradle-$GRADLE_VERSION-all.zip" \
  "$wrapper_properties"
grep -Fq "distributionSha256Sum=$GRADLE_DISTRIBUTION_SHA256" "$wrapper_properties"
test -s "$wrapper_jar"
actual_wrapper_sha256="$(sha256sum "$wrapper_jar" | awk '{print $1}')"
if [[ "$actual_wrapper_sha256" != "$GRADLE_WRAPPER_SHA256" ]]; then
  echo "Gradle wrapper SHA-256 mismatch: $actual_wrapper_sha256" >&2
  exit 1
fi

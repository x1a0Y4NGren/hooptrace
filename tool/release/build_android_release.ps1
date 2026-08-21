[CmdletBinding()]
param(
    [string]$Version = "",
    [switch]$SkipChecks
)

$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "release_helpers.ps1")

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$keyPropertiesPath = Join-Path $repoRoot "android\key.properties"
$generatedRegistrant = Join-Path $repoRoot "android\app\src\main\java\io\flutter\plugins\GeneratedPluginRegistrant.java"
$sourceApk = Join-Path $repoRoot "build\app\outputs\flutter-apk\app-release.apk"
$pubspec = Get-Content -Raw (Join-Path $repoRoot "pubspec.yaml")
$appMetadata = Get-Content -Raw (Join-Path $repoRoot "lib\app\app_metadata.dart")
$expectedApplicationId = "io.github.x1a0y4ngren.hooptrace"

$versionMatch = [regex]::Match(
    $pubspec,
    "(?m)^version:\s+([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)\s*$"
)
if (-not $versionMatch.Success) {
    throw "pubspec.yaml must declare a semantic version and numeric build number."
}
$declaredVersion = $versionMatch.Groups[1].Value
$declaredBuildNumber = $versionMatch.Groups[2].Value
if ($Version -and $Version -ne $declaredVersion) {
    throw "Requested version $Version does not match pubspec.yaml version $declaredVersion."
}
$Version = $declaredVersion

$expectedMetadataVersion = "$Version+$declaredBuildNumber"
if ($appMetadata -notmatch "'$([regex]::Escape($expectedMetadataVersion))'") {
    throw "lib/app/app_metadata.dart does not match version $expectedMetadataVersion."
}

$releaseDirectory = Join-Path $repoRoot "build\release-assets\v$Version"
$releaseApkName = "HoopTrace-v$Version-android.apk"
$releaseApk = Join-Path $releaseDirectory $releaseApkName

$trackedChanges = & git -C $repoRoot status --porcelain --untracked-files=no
if ($LASTEXITCODE -ne 0) { throw "Unable to inspect Git status." }
if ($trackedChanges) {
    throw "Tracked files are not clean. Commit the release candidate before building."
}

if (-not (Test-Path -LiteralPath $keyPropertiesPath)) {
    throw "Missing android/key.properties. Run tool/release/setup_android_signing.ps1 first."
}

if ($env:HOOPTRACE_ALLOW_UNSIGNED_RELEASE -eq "true") {
    throw "HOOPTRACE_ALLOW_UNSIGNED_RELEASE must not be enabled for an upstream release."
}

Push-Location $repoRoot
try {
    if (Test-Path -LiteralPath $generatedRegistrant) {
        Remove-Item -LiteralPath $generatedRegistrant
    }

    flutter clean
    if ($LASTEXITCODE -ne 0) { throw "flutter clean failed." }

    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }

    if (-not $SkipChecks) {
        dart format --output=none --set-exit-if-changed .
        if ($LASTEXITCODE -ne 0) { throw "Formatting check failed." }

        flutter analyze
        if ($LASTEXITCODE -ne 0) { throw "Static analysis failed." }

        flutter test
        if ($LASTEXITCODE -ne 0) { throw "Tests failed." }
    }

    if (Test-Path -LiteralPath $generatedRegistrant) {
        Remove-Item -LiteralPath $generatedRegistrant
    }

    flutter build apk --release
    if ($LASTEXITCODE -ne 0) { throw "Signed release build failed." }
} finally {
    Pop-Location
}

if (-not (Test-Path -LiteralPath $sourceApk)) {
    throw "Release APK was not created at $sourceApk."
}
if (-not (Test-Path -LiteralPath $generatedRegistrant)) {
    throw "Flutter did not generate the Android runtime plugin registrant."
}
$registrantContent = Get-Content -Raw -LiteralPath $generatedRegistrant
if ($registrantContent -match "IntegrationTestPlugin") {
    throw "The release plugin registrant still contains integration_test."
}
$requiredRuntimePlugins = @(
    "JniPlugin",
    "JniFlutterPlugin",
    "Sqlite3FlutterLibsPlugin"
)
foreach ($pluginClass in $requiredRuntimePlugins) {
    if ($registrantContent -notmatch [regex]::Escape($pluginClass)) {
        throw "The release plugin registrant is missing $pluginClass."
    }
}
Remove-Item -LiteralPath $generatedRegistrant

$androidSdk = $env:ANDROID_SDK_ROOT
if (-not $androidSdk) { $androidSdk = $env:ANDROID_HOME }
if (-not $androidSdk) {
    $localProperties = Get-Content (Join-Path $repoRoot "android\local.properties")
    $sdkLine = $localProperties | Where-Object { $_ -like "sdk.dir=*" } | Select-Object -First 1
    if ($sdkLine) {
        $androidSdk = $sdkLine.Substring("sdk.dir=".Length).Replace("\\", "\")
    }
}
if (-not $androidSdk) { throw "Android SDK path could not be resolved." }

$buildTools = Get-ChildItem -LiteralPath (Join-Path $androidSdk "build-tools") -Directory |
    Sort-Object { [version]$_.Name } -Descending |
    Select-Object -First 1
if (-not $buildTools) { throw "No Android SDK build-tools installation was found." }
$apksigner = Join-Path $buildTools.FullName "apksigner.bat"
$aapt = Join-Path $buildTools.FullName "aapt.exe"
if (-not (Test-Path -LiteralPath $apksigner)) { throw "apksigner was not found." }
if (-not (Test-Path -LiteralPath $aapt)) { throw "aapt was not found." }

New-Item -ItemType Directory -Force -Path $releaseDirectory | Out-Null
Copy-Item -LiteralPath $sourceApk -Destination $releaseApk -Force

$packageOutput = & $aapt dump badging $releaseApk 2>&1
if ($LASTEXITCODE -ne 0) { throw "APK package metadata inspection failed." }
$packageLine = $packageOutput | Where-Object { $_ -like "package:*" } | Select-Object -First 1
if (-not $packageLine) { throw "APK package metadata was not found." }
if ($packageLine -notmatch "name='$([regex]::Escape($expectedApplicationId))'") {
    throw "APK application ID does not match $expectedApplicationId."
}
if ($packageLine -notmatch "versionCode='$([regex]::Escape($declaredBuildNumber))'") {
    throw "APK versionCode does not match $declaredBuildNumber."
}
if ($packageLine -notmatch "versionName='$([regex]::Escape($Version))'") {
    throw "APK versionName does not match $Version."
}
[IO.File]::WriteAllLines(
    (Join-Path $releaseDirectory "PACKAGE.txt"),
    [string[]]$packageOutput,
    [Text.UTF8Encoding]::new($false)
)

$certificateOutput = & $apksigner verify --verbose --print-certs $releaseApk 2>&1
if ($LASTEXITCODE -ne 0) { throw "APK signature verification failed." }
[IO.File]::WriteAllLines(
    (Join-Path $releaseDirectory "CERTIFICATE.txt"),
    [string[]]$certificateOutput,
    [Text.UTF8Encoding]::new($false)
)

$permissionOutput = & $aapt dump permissions $releaseApk 2>&1
if ($LASTEXITCODE -ne 0) { throw "APK permission inspection failed." }
[IO.File]::WriteAllLines(
    (Join-Path $releaseDirectory "PERMISSIONS.txt"),
    [string[]]$permissionOutput,
    [Text.UTF8Encoding]::new($false)
)

$hash = Get-CompatibleSha256 -LiteralPath $releaseApk
[IO.File]::WriteAllText(
    (Join-Path $releaseDirectory "SHA256SUMS"),
    "$hash  $releaseApkName`n",
    [Text.UTF8Encoding]::new($false)
)

Write-Host "Signed release assets: $releaseDirectory"
Write-Host "SHA-256: $hash"

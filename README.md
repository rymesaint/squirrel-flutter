# squirrel

Squirrel for Flutter apps.

## Getting Started

### Installation
```
flutter pub add squirrel --dev --git-url https://github.com/RustamG/squirrel-flutter.git
```

### Launch

```
flutter build windows
flutter pub run squirrel:installer_windows
```


### Configuration
Parameters can be specified either in pubspec.yaml or passed as command-line arguments. Values passed as command-line arguments have higher priority.

Example of specifying the parameters via command-line:
```
flutter pub run squirrel:installer_windows --authors "My comapny" --appFriendlyName "My App"
```

List of available parameters:
- `releaseDirectory` - where the result files will be placed.
- `packageName` (optional) - Name of the directory where your app will be installed. If not provided, the `name` from pubspec.yaml is used.
- `mainExeName` (optional) - Name of application .exe file. Falls back to `packageName`.
- `appFriendlyName` (required) - Name of the app. If not provided, `title` from pubspec.yaml is used.
- `version` (optional) - Version of the package. If not provided, top-level value from pubspec.yaml is used.
- `authors` (required) - Authors separated by comma. Required by NuGet. Falls back to top-level `authors` in pubspec.yaml which is currently [deprecated](https://dart.dev/tools/pub/pubspec#authorauthors).
- `appDescription` (optional) - App description. Falls back to `appFriendlyName`.
- `appIcon` (required) - Icon for the installer
- `loadingGif` (optional) - A path to GIF file which will be displayed during initial installation of the app.
- `uninstallIconPngUrl` (required) - URL of the icon for the uninstaller in PNG format, 128x128.
- `setupIcon` (optional) - Path to a .ico file for the Setup.exe. Falls back to `appIcon`.
- `releaseUrl` (optional) - URL to run SyncReleases.exe
- `buildEnterpriseMsiPackage` (optional, default: false) - whether to build .msi. `--no-msi` flag for squirrel.exe
- `dontBuildDeltas` (optional) - `--no-delta` flag for squirrel.exe
- `certificateFile` - **TBD**
- `overrideSigningParameters` - **TBD**


Example of configuration via pubspec.yaml:
```
squirrel:
  windows:
    appIcon: "windows/runner/resources/app_icon.ico"
    appFriendlyName: "blaf"
    appDescription: "blaf"
    authors: "Bob"
    certificateFile: "foo"
    overrideSigningParameters: "bar"
    loadingGif: "baz"
    uninstallIconPngUrl: "blahhgh"
    setupIcon: "bamf"
    releaseDirectory: "blaf"
    buildEnterpriseMsiPackage: false
    dontBuildDeltas: false
```
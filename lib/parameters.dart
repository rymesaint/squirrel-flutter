import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:squirrel/utils.dart';

const youDontHaveAProperPubspec = '''
Your app's pubspec.yaml doesn't have a Squirrel section, it is Highly Recommended 
to have one! Here's an example section with all of the available parameters, though
most are optional:

squirrel:
  windows:
    certificateFile: "foo"
    overrideSigningParameters: "bar"
    loadingGif: "baz"
    appIcon: "blamf"
    authors: "blaf"
    uninstallIconPngUrl: "blahhgh"
    appFriendlyName: "blaf"
    appDescription: "blaf"
    setupIcon: "bamf"
    releaseDirectory: "blaf"
    buildEnterpriseMsiPackage: false
    dontBuildDeltas: false
''';

const defaultUninstallPngUrl = 'https://fill/in/this/later';

String _stringOrThrow(dynamic d, String err) {
  if (d == null) {
    throw Exception(err);
  }

  return d.toString();
}

String _parseVersion(dynamic v) {
  final ver = _stringOrThrow(v, 'Your app needs a version');
  return ver.replaceFirst(RegExp(r'[-+].*$'), '').trimLeft();
}

String _parseAuthor(dynamic a) {
  final author = _stringOrThrow(a, 'Authors section is required');
  return author.replaceAll(RegExp(r' <.*?>'), '').trimLeft();
}

class Parameters {
  final String packageName;
  final String mainExeName;
  final String appFriendlyName;
  final String appDescription;
  final String appIcon;
  final String version;
  final String authors;
  final String? certificateFile;
  final String? overrideSigningParameters;
  final String loadingGif;
  final String? uninstallIconPngUrl;
  final String? setupIcon;
  final String releaseDirectory;
  final String? releaseUrl;
  final bool buildEnterpriseMsiPackage;
  final bool dontBuildDeltas;

  Parameters({
    required this.packageName,
    required this.mainExeName,
    required this.appFriendlyName,
    required this.appDescription,
    required this.appIcon,
    required this.version,
    required this.authors,
    this.certificateFile,
    this.overrideSigningParameters,
    required this.loadingGif,
    this.uninstallIconPngUrl,
    this.setupIcon,
    required this.releaseDirectory,
    this.releaseUrl,
    required this.buildEnterpriseMsiPackage,
    required this.dontBuildDeltas,
  });

  factory Parameters.fromYamlAndArgs(dynamic appPubspec, List<String> args) {
    dynamic windowsSection = appPubspec['squirrel']?['windows'];
    final arguments = _setupArgParser().parse(args);
    if (windowsSection == null) {
      stdout.writeln(youDontHaveAProperPubspec);
      windowsSection = {};
    }

    final packageName = arguments['packageName']?.toString() ??
        windowsSection['packageName']?.toString() ??
        appPubspec['name'].toString();
    final mainExeName = arguments['mainExeName']?.toString() ??
        windowsSection['mainExeName']?.toString() ??
        packageName;
    final appFriendlyName = _stringOrThrow(
        arguments['appFriendlyName'] ??
            windowsSection['appFriendlyName'] ??
            appPubspec['title'],
        'Your app needs a title!');
    final version = _parseVersion(arguments['version'] ??
        windowsSection['version'] ??
        appPubspec['version']);
    final authors = _parseAuthor(arguments['authors'] ??
        appPubspec['authors'] ??
        windowsSection['authors']);
    final description = _stringOrThrow(
        arguments['appDescription'] ??
            windowsSection['appDescription'] ??
            appFriendlyName,
        'Your app must have a description');
    final appIcon = canonicalizePubspecPath(_stringOrThrow(
        arguments['appIcon'] ?? windowsSection['appIcon'],
        'Your app must have an icon'))!;
    final certificateFile = canonicalizePubspecPath(
        arguments['certificateFile']?.toString() ??
            windowsSection['certificateFile']?.toString());
    final overrideSigningParameters =
        arguments['overrideSigningParameters']?.toString() ??
            windowsSection['overrideSigningParameters']?.toString() ??
            _generateSigningParams(certificateFile);
    final loadingGif = canonicalizePubspecPath((arguments['loadingGif'] ??
            windowsSection['loadingGif'] ??
            path.join(rootDir, 'vendor', 'default-loading.gif'))
        .toString())!;
    final uninstallIconPngUrl = (arguments['uninstallIconPngUrl'] ??
            windowsSection['uninstallIconPngUrl'] ??
            defaultUninstallPngUrl)
        .toString();
    final setupIcon = canonicalizePubspecPath(
        (arguments['setupIcon'] ?? windowsSection['setupIcon'] ?? appIcon)
            .toString());
    final releaseDirectory = canonicalizePubspecPath(
        arguments['releaseDirectory']?.toString() ??
            windowsSection['releaseDirectory']?.toString() ??
            path.join(appDir, 'build'))!;
    final releaseUrl = canonicalizePubspecPath((arguments['releaseUrl'] ??
            windowsSection['releaseUrl'] ??
            Platform.environment['SQUIRREL_RELEASE_URL'])
        ?.toString());
    final buildEnterpriseMsiPackage = (arguments['buildEnterpriseMsiPackage'] ??
                windowsSection['buildEnterpriseMsiPackage']) ==
            true
        ? true
        : false;
    final dontBuildDeltas =
        (arguments['dontBuildDeltas'] ?? windowsSection['dontBuildDeltas']) ==
                true
            ? true
            : false;

    if (certificateFile != null && overrideSigningParameters != null) {}

    return Parameters(
      packageName: packageName,
      mainExeName: mainExeName,
      appFriendlyName: appFriendlyName,
      appDescription: description,
      appIcon: appIcon,
      version: version,
      authors: authors,
      certificateFile: certificateFile,
      overrideSigningParameters: overrideSigningParameters,
      loadingGif: loadingGif,
      uninstallIconPngUrl: uninstallIconPngUrl,
      setupIcon: setupIcon,
      releaseDirectory: releaseDirectory,
      releaseUrl: releaseUrl,
      buildEnterpriseMsiPackage: buildEnterpriseMsiPackage,
      dontBuildDeltas: dontBuildDeltas,
    );
  }
}

ArgParser _setupArgParser() {
  return ArgParser()
    ..addOption('packageName')
    ..addOption('mainExeName')
    ..addOption('appFriendlyName')
    ..addOption('authors')
    ..addOption('version')
    ..addOption('appDescription')
    ..addOption('appIcon')
    ..addOption('certificateFile')
    ..addOption('overrideSigningParameters')
    ..addOption('loadingGif')
    ..addOption('uninstallIconPngUrl')
    ..addOption('setupIcon')
    ..addOption('releaseDirectory')
    ..addOption('releaseUrl')
    ..addFlag('buildEnterpriseMsiPackage')
    ..addFlag('dontBuildDeltas');
}

String? _generateSigningParams(String? certificateFile) {
  final certPass = Platform.environment['SQUIRREL_CERT_PASSWORD'];
  final overrideParams =
      Platform.environment['SQUIRREL_OVERRIDE_SIGNING_PARAMS'];

  if (overrideParams != null) {
    return overrideParams;
  }

  if (certPass == null) {
    if (certificateFile == null) return null;

    throw Exception(
        'You must set either the SQUIRREL_CERT_PASSWORD or the SQUIRREL_OVERRIDE_SIGNING_PARAMS environment variable');
  }

  return '/a /f \"$certificateFile\" /p $certPass /v /fd sha256 /tr http://timestamp.digicert.com /td sha256';
}

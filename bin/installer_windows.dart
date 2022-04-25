#!/usr/bin/env dart

library installer_windows;

import 'dart:io';

import 'package:jinja/jinja.dart';
import 'package:path/path.dart' as path;
import 'package:squirrel/parameters.dart';
import 'package:squirrel/utils.dart';
import 'package:yaml/yaml.dart';


Future<int> main(List<String> args) async {
  await initPaths();

  final pubspecYaml = path.join(appDir, 'pubspec.yaml');
  final yaml = loadYaml(await File(pubspecYaml).readAsString());

  final template = Environment().fromString(
      await File(path.join(rootDir, 'nuspec.jinja')).readAsString());

  final pubspec = Parameters.fromYamlAndArgs(yaml, args);
  final buildDirectory = canonicalizePubspecPath(
      path.join('build', 'windows', 'runner', 'Release'))!;

  // Copy Squirrel.exe into the app dir and squish the setup icon in
  final tgtSquirrel = path.join(buildDirectory, 'squirrel.exe');
  if (!await File(tgtSquirrel).exists()) {
    await File(path.join(rootDir, 'vendor', 'squirrel.exe')).copy(tgtSquirrel);
  }

  if (pubspec.setupIcon != null) {
    await runUtil(
        'rcedit.exe', ['--set-icon', pubspec.setupIcon!, tgtSquirrel]);
  }

  // Squish the icon into main exe
  await runUtil('rcedit.exe', [
    '--set-icon',
    pubspec.appIcon,
    path.join(buildDirectory, '${pubspec.mainExeName}.exe')
  ]);

  // ls -r to get our file tree and create a temp dir
  final filePaths = await Directory(buildDirectory)
      .list(recursive: true)
      .where((f) => f.statSync().type == FileSystemEntityType.file)
      .map((f) => f.path.replaceFirst(buildDirectory, '').substring(1))
      .toList();

  final nuspecContent = template
      .render(
          name: pubspec.packageName,
          title: pubspec.appFriendlyName,
          description: pubspec.appDescription,
          version: pubspec.version,
          authors: pubspec.authors,
          iconUrl: pubspec.uninstallIconPngUrl,
          additionalFiles: filePaths.map((f) => ({'src': f, 'target': f})))
      .toString();

  // NB: NuGet sucks
  final tmpDir = await Directory.systemTemp.createTemp('si-');
  final nuspec = path.join(tmpDir.path, 'spec.nuspec');
  await File(nuspec).writeAsString(nuspecContent);
  await runUtil('nuget.exe', [
    'pack',
    nuspec,
    '-BasePath',
    buildDirectory,
    '-OutputDirectory',
    tmpDir.path,
    '-NoDefaultExcludes'
  ]);

  final nupkgFile =
      (await tmpDir.list().firstWhere((f) => f.path.contains('.nupkg'))).path;

  // Prepare the release directory
  final releaseDir = Directory(pubspec.releaseDirectory);
  if (await releaseDir.exists()) {
    await releaseDir.delete(recursive: true);
  }

  await releaseDir.create(recursive: true);

  // Run syncReleases
  if (pubspec.releaseUrl != null) {
    if (pubspec.releaseUrl!.startsWith('http://') &&
        Platform.environment[
                'SQUIRREL_I_KNOW_THAT_USING_HTTP_URLS_IS_REALLY_BAD'] ==
            null) {
      throw Exception('''
You MUST use an HTTPS URL for updates, it is *extremely* unsafe for you to 
update software via HTTP. If you understand this and you are absolutely sure 
that you are not putting your users at risk, set the environment variable
SQUIRREL_I_KNOW_THAT_USING_HTTP_URLS_IS_REALLY_BAD to 'I hereby promise.'
''');
    }

    await runUtil(
        'SyncReleases.exe', ['-r', releaseDir.path, '-u', pubspec.releaseUrl!]);
  }

  // Releasify!
  var squirrelExeArgs = [
    '--releasify',
    nupkgFile,
    '--releaseDir',
    releaseDir.path,
    '--loadingGif',
    pubspec.loadingGif,
  ];

  // NB: We let the Pubspec class handle generating the default signing
  // parameters so from the perspective of this part of the code, there is *only*
  // either a "custom" signing parameter, or nothing
  if (pubspec.overrideSigningParameters != null) {
    squirrelExeArgs.addAll(['-n', pubspec.overrideSigningParameters!]);
  }

  if (pubspec.dontBuildDeltas) {
    squirrelExeArgs.add('--no-delta');
  }

  if (!pubspec.buildEnterpriseMsiPackage) {
    squirrelExeArgs.add('--no-msi');
  }

  if (pubspec.setupIcon != null) {
    squirrelExeArgs.addAll(['--setupIcon', pubspec.setupIcon!]);
  }

  await runUtil('squirrel.exe', squirrelExeArgs);
  return 0;
}

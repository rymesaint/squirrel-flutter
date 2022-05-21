import 'dart:io';

import 'package:package_config/package_config.dart' show findPackageConfig;
import 'package:path/path.dart' as path;

late String rootDir;
late String appDir;

Future<void> initPaths() async {
  final packagesConfig = await findPackageConfig(Directory.current);
  if (packagesConfig == null) {
    throw Exception('Failed to locate or read package config.');
  }

  final squirrelPackage = packagesConfig.packages
      .firstWhere((package) => package.name == 'squirrel');
  rootDir = path.join(path.fromUri(squirrelPackage.packageUriRoot), '..');
  appDir = path.canonicalize(
      path.join(path.dirname(path.fromUri(Platform.packageConfig!)), '..'));
}

String? canonicalizePubspecPath(String? relativePath) {
  if (relativePath == null) {
    return null;
  }

  if (path.isAbsolute(relativePath)) {
    return relativePath;
  }

  if (relativePath.startsWith('http://') ||
      relativePath.startsWith('https://')) {
    return relativePath;
  }

  return path.normalize(path.join(appDir, relativePath));
}

Future<ProcessResult> runUtil(String name, List<String> args,
    {String? cwd}) async {
  final cmd = path.join(rootDir, 'vendor', name);
  final ret = await Process.run(cmd, args, workingDirectory: cwd);

  if (ret.exitCode != 0) {
    final msg =
        "Failed to run $cmd ${args.join(' ')}\n${ret.stdout}\n${ret.stderr}";
    throw Exception(msg);
  }

  return ret;
}

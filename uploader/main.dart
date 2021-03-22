import 'dart:io';

import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:meta/meta.dart';

void main(List<String> arguments) {
  final String url = 'https://appwrite.formation-flutter.fr/v1';
  // TODO
  final String projectId = '-';
  // TODO
  final String apiKey = '-';
  // TODO
  final String functionId = '-';
  // TODO
  final String projectName = 'cli';

  run(
      url: url,
      projectId: projectId,
      projectApiKey: apiKey,
      functionId: functionId,
      projectName: projectName,
      launchFunction: true);
}

void run(
    {@required String url,
    @required String projectId,
    @required String projectApiKey,
    @required String functionId,
    @required String projectName,
    bool launchFunction = true}) async {
  final client = Client();

  client.setEndpoint(url).setProject(projectId).setKey(projectApiKey);

  // tar -zcvf code.tar.gz storage_cleaner
  Directory directory = Directory.current;

  // Delete previous archive
  await Process.run('rm', ['code.tar.gz'],
      workingDirectory: directory.parent.path);

  // Generate a new one
  await Process.run(
      'tar',
      [
        '--exclude=bin',
        '--exclude=.DS_Store',
        '--exclude=.dart_tool',
        '--exclude=.idea',
        '--exclude=.gitignore',
        '--exclude=.packages',
        '--exclude=CHANGELOG.md',
        '--exclude=$projectName.html',
        '--exclude=$projectName.iml',
        '--exclude=README.md',
        '-zcvf',
        'code.tar.gz',
        projectName,
      ],
      workingDirectory: directory.parent.path);

  print('Upload de la fonction $functionId en cours…');

  try {
    var functions = Functions(client);

    // Upload the function
    var response = await functions.createTag(
        functionId: functionId,
        command: 'dart lib/main.dart',
        code: await MultipartFile.fromFile(
          '${directory.parent.path}/code.tar.gz',
        ));

    print('Upload OK');

    // Activate the function
    print('Activation de la fonction en cours…');
    await functions.updateTag(
        functionId: functionId, tag: response.data['\$id']);
    print('Activation de la fonction OK');

    // Launch it
    if (launchFunction) {
      print('Exécution de la fonction…');
      await functions.createExecution(functionId: '60586950274d2');
    }

    await Process.run('rm', ['code.tar.gz'],
        workingDirectory: directory.parent.path);
  } on AppwriteException catch (err, stackTrace) {
    print('Une erreur ${err.code} est survenue (${err.message})!');
    print(stackTrace);
  }

  print('Terminé !');
}

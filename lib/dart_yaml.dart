import 'package:ansicolor/ansicolor.dart';
import 'package:yaml/yaml.dart';
import 'package:indent/indent.dart';
import 'dart:io';
import 'dart:convert';

void testYAMLDirectory(String directoryPath) async {
  var testDirectory = Directory(directoryPath);
  if (!testDirectory.existsSync()) {
    throw ('Testing Directory does not exist!');
  }

  var paths = getTestFolders(testDirectory);

  // Not really needed, but placed here to demonstrate what the variable looks like.
  var results = {
    'ValidSuccess': [],
    'ValidFailure': [],
    'ValidIncorrect': [],
    'InvalidSuccess': [],
    'InvalidFailure': [],
    'JSONError': [],
  };

  await paths.forEach((path) => testYAML(results, path));
  printErrors(results);
  printResults(results);
}

void printResults(Map<String, List> results) {
  print('Results');
  print('==================================================');
  print('Valid YAML:');
  print('\tSuccessful Parsing:\t${results['ValidSuccess'].length ?? 0}');
  print('\tIncorrect Parsing:\t${results['ValidIncorrect'].length ?? 0}');
  print('\tError while Parsing:\t${results['ValidFailure'].length ?? 0}\n');
  print('Invalid YAML:');
  print('\tSuccessful Recognition:\t${results['InvalidSuccess'].length ?? 0}');
  print('\tFailure to Recognize:\t${results['InvalidFailure'].length ?? 0}\n');
  print('JSON Errors:\t${results['JSONError'].length ?? 0}');
}

void printErrors(Map<String, List> results) {
  if (results['ValidFailure'].isEmpty &&
      results['ValidIncorrect'].isEmpty &&
      results['InvalidFailure'].isEmpty) {
    print('All tests passed!');
    return;
  }

  // AnsiPen for colored error messages
  var redPen = AnsiPen()..xterm(009);
  var redHighlight = AnsiPen()
    ..black()
    ..xterm(001, bg: true);
  var orangePen = AnsiPen()..xterm(208);

  results['ValidFailure'].asMap().forEach((index, testInfo) {
    print(redHighlight(' FAIL ') +
        '  ${testInfo['testCase']} - ${testInfo['description']}');
    print(redPen('\t#${index + 1}- Failed to parse valid YAML.'));
    print('''${testInfo['err']}\n'''.indent(8));
  });

  print('\n\n');

  results['ValidIncorrect'].asMap().forEach((index, testInfo) {
    print(redHighlight(' FAIL ') +
        '  ${testInfo['testCase']} - ${testInfo['description']}');
    print(redPen(
        '\t#${index + 1} - Actual output differs from expected output.'));
    print('''actual output:   \t${testInfo['actualOutputJSON']}'''.indent(8));
    print('''expected output: \t${testInfo['expectedOutputJSON']}'''.indent(8));
  });

  results['InvalidFailure'].asMap().forEach((index, testInfo) {
    print(redHighlight(' FAIL ') +
        '  ${testInfo['testCase']} - ${testInfo['description']}');
    print(redPen('\t#${index + 1} - Failed to recognize error yaml.'));

    print(orangePen('\tInput:'));
    print('''${testInfo['input']}\n'''.indent(8));
    print(orangePen('\tParsed it as:'));
    print('''${testInfo['actualOutputJSON']}\n\n'''.indent(8));
  });

  print('\n\n');

  results['JSONError'].asMap().forEach((index, testInfo) {
    print(redHighlight(' FAIL ') +
        '  ${testInfo['testCase']} - ${testInfo['description']}');
    print(redPen(
        '\t#${index + 1} - Input JSON could not be parsed.\n\n'.indent(8)));
  });
}

/// Gets the test folders in the larger test directory.
/// Hinges on the fact that test folders should be the ones containing in.yaml.
Stream<String> getTestFolders(Directory testDirectory) {
  // Recursively grab all the files in the testing directory.
  var entityStream = testDirectory.list(recursive: true, followLinks: false);
  entityStream =
      entityStream.where((entity) => entity.path.endsWith('in.yaml'));

  return entityStream.map((entity) =>
      entity.path.substring(0, entity.path.length - 'in.yaml'.length - 1));
}

void testYAML(Map<String, List> results, String path) {
  // Only the input and description files can be said to be present in all test folders
  var inputFile = File('$path/in.yaml');
  var descriptionFile = File('$path/==='); // Description of the test.

  // Expected Output can come from either `out.yaml', `in.json`, or `emit.yaml`.
  var output;

  // Test directories for invalid YAML have an error file.
  var hasError = File('$path/error').existsSync();

  // Gets the test case number from the test folder.
  var testCase = path.split('/').last;

  // If input cannot be found, throw an error.
  if (!inputFile.existsSync()) {
    throw ('Input YAML for testing in $path cannot be found.');
  }

  // Description should be in any folder, but is not mission critical, so we can afford to do this.
  var description;
  try {
    if (descriptionFile.existsSync()) {
      description = descriptionFile.readAsStringSync().trim();
    }
  } catch (e) {
    description = '';
  }

  var expectedOutputJSON = '';

  try {
    // The "truth" for the test should come from `in.json`.
    if (File('$path/in.json').existsSync()) {
      output = File('$path/in.json').readAsStringSync();
      expectedOutputJSON = json.encode([json.decode(output)]);
    }
  } catch (err) {
    updateResults(results, 'JSONError',
        {'testCase': testCase, 'err': err, 'description': description});
  }

  try {
    var input = inputFile.readAsStringSync();

    // Use loadYAMLStream because some tests have multiple documents.
    var inputYAML = loadYamlStream(input);
    var actualOutputJSON = json.encode(inputYAML);

    var testInformation = {
      'testCase': testCase,
      'input': input,
      'actualOutputJSON': actualOutputJSON,
      'expectedOutputJSON': expectedOutputJSON,
      'description': description
    };

    // If it gets to here, both input and output are parsed.
    // If there was supposed to be an error, this will be a failure to detect invalid YAML.
    if (hasError) {
      updateResults(results, 'InvalidFailure', testInformation);
    } else if (actualOutputJSON == expectedOutputJSON) {
      updateResults(results, 'ValidSuccess', testInformation);
    } else {
      updateResults(results, 'ValidIncorrect', testInformation);
    }
  } catch (err) {
    if (hasError) {
      updateResults(results, 'InvalidSuccess',
          {'testCase': testCase, 'err': err, 'description': description});
    } else {
      updateResults(results, 'ValidFailure',
          {'testCase': testCase, 'err': err, 'description': description});
    }
  }
}

void updateResults(Map<String, List> results, String key,
    Map<String, dynamic> testInformation) {
  results.update(key, (oldValues) {
    oldValues.add(testInformation);
    return oldValues;
  }, ifAbsent: () => [testInformation]);
}

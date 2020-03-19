import 'package:dart_yaml/dart_yaml.dart';

void main(List<String> arguments) async {
  // Declare test directory
  var testDirectoryPath = './yaml-test-suite';

  testYAMLDirectory(testDirectoryPath);
}

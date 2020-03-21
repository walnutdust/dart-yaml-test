# Dart YAML Test

An exploratory repository made to test `package:yaml` on the examples in 
[yaml-test-suite](https://github.com/yaml/yaml-test-suite).

## Usage

```bash
$ git clone https://github.com/walnutdust/dart-yaml-test.git
$ cd dart-yaml-test
$ pub get
$ dart bin/main.dart
```

## Results

```bash
Results
==================================================
Valid YAML:
	Successful Parsing:	184
	Incorrect Parsing:	22
	Error while Parsing:	42

Invalid YAML:
	Successful Recognition:	56
	Failure to Recognize:	16

	JSON Errors:	19
```

## License

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

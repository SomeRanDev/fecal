package fecal.tester;

function help() {
	Sys.println("Fecal tester options

======================================================================
IMPORTANT COMMANDS
======================================================================

* --help
Shows this output.

* --update-intended
The C++ output is generated in the `intended` folder.

* --os-exclusive
Only tests with intended folders exclusive to this operating system will be processed.

* --simulate=SystemName
Simulates a test on a different operating system. This can be helpful for generating other systems' Haxe output.

* --test=TestName
This option can be added multiple times to specify only certain tests should be run.

* --build=[only|always|never]
Controls whether the build/execution tests occur.
  By default, the build/execution will only run if the Haxe output comparison tests are passed.
  [only]   The Haxe compilation and comparison tests are skipped.
  [always] The build/execution tests occur even if the Haxe output comparison tests fail.
  [never]  The build/execution test never occur even if the Haxe output comparisons tests succeed.

======================================================================
DEBUG
======================================================================

* --show-output
The output of the build and execution is always shown, even if it ran successfully.

* --no-details
The list of output lines that do not match the tests are omitted from the output.

* --dev-mode
Enables `--always-compile`, `--show-output`, and `--no-details`.
");
}

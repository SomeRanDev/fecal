package fecal;

import fecal.data.FolderNames;
import fecal.tester.Tester;
import fecal.tester.TesterResult;

/**
	Runs Fecal tests.

	```haxe
	class MyCustomTester extends FecalTest {
		public override function generateHaxeCompilationArguments(
			outputDirectory: String,
			testDirectory: String,
			hxmlFile: {
				name: String,
				absolutePath: String
			},
			arguments: Arguments,
		): Array<String> {
			return [
				"--no-opt",
				'-js ${data.outputDirectory}/Main.js',
				'"${data.hxmlFile.absolutePath}"'
			];
		}
	}

	function main() {
		// The path to the folder containing the tests.
		final testsFolder = "tests";

		// The names of the folders read/generated.
		final folderNames = {
			output: "output",
			intendedOutput: "intended",
			build: "bin"
		};

		final tester = new MyCustomTester(testsFolder, folderNames);
		final result = Fecal.test(tester);

		switch(result) {
			case Ok(PassedTests(testCount)): {
				Sys.println("All tests passed!");
			}
			case _: {
				// Handle the various possible fail states...
			}
		}
	}
	```
**/
class Fecal {
	public static function test(test: FecalTest): Error<TesterResult> {
		final tester = new Tester(test);
		return tester.run();
	}
}

# Haxe Fecal
A Haxe testing framework focused on tracking and validating the file output of a Haxe compilation. This was primarily created for custom Haxe target unit testing.

&nbsp;

## How it Works

The structure of a Fecal test is as follows:
```
 MyFrameworkTests/
 |
 \- MyTest1
	|
	|- intended/
	|  |- YourOutput1.file
	|  \- YourOutput2.file
	|
	|- .gitignore
	|- Test.hxml
	\- Main.hx
```

First you should have the main directory that contains all the tests. It's named `MyFrameworkTests` in this case. In that directory, each sub-directory represents a test. `MyTest1` is a test in this example.

Within that directory should be a Haxe project that uses your framework AND a pre-generated output folder with the expected output. In this case, that folder is named `intended`. When the test is run, its output will be placed in an `output` folder. If the contents of `intended` and `output` are the same, the test succeeds!

&nbsp;

## How to Use

Create a new `.hxml` file in your project, presumably in a `test/` folder, and give it something like this:
```hxml
-lib fecal
--cwd .
--run Test
```

This ensures that:
1. The Fecal library is used.
2. The current working directory will be a consistent location.
3. Your main test script `Test` will run.

Taking a peak into `Test.hx`, you should have something like this:
```haxe
package;

function main() {
	final result = Fecal.test(
		// This is the relative path to the directory of test directories.
		"MyFrameworkTests",

		// This parameter let's you configure the names of your test folders.
		// We can pass `null` just to use the defaults.
		null,

		// This callback configures the arguments for the Haxe compilation in a test.
		function(data: GenerateTestArgumentsData): Array<String> {
			return [
				// Depending on how you set up your test, you may need to directly set
				// source paths to your library's source folder and extraParams.hxml.
				"-cp ../src",
				"../extraParams.hxml",

				// Alternatively, you could use `haxelib dev` and call your lib directly:
				// "-lib myLib",

				// Make sure to include the source folder for this specific test.
				"-cp " + data.testDirectory,

				// We need to generate output to check!
				"-js " + data.outputDirectory,

				// And then finally, add this test's `.hxml` file.
				"\"" + data.hxmlFile.absolutePath + "\""
			];
		},

		// If you'd like to add build and execution steps to your test, you can add callbacks
		// to generate the commands for those here.
		null,
		null,
	);

    // There is an exhaustive list of possible errors and outputs `result` can be, but for now
    // we just check to see if `PassedTests` was returned. This indicates all the tests were successful! 
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

package fecal.tester;

import fecal.data.FolderNames;
import fecal.data.Output;
import fecal.tester.Arguments;
import fecal.tester.Help.help;
import fecal.Utils.printlnErr;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.Process;

/**
	The class that contains the actual testing code.
**/
class Tester {
	var test: FecalTest;
	var arguments: Arguments;

	/**
		Constructor.
	**/
	public function new(test: FecalTest) {
		this.test = test;
		arguments = Arguments.initFromArgs();
	}

	/**
		Runs the tests.
	**/
	public function run(): Error<TesterResult> {
		// ------------------------------------
		// Print help.
		if(arguments.help) {
			help();
			return Ok(PrintedHelp);
		}

		// ------------------------------------
		// Get a list of all tests.
		var tests = switch(checkAndReadDir(test.testsDirectory)) {
			case Ok(tests): tests;
			case error: return error.convert();
		}
		if((arguments.specifiedTests?.length ?? 0) > 0) {
			tests = tests.filter(t -> arguments.specifiedTests.contains(t));
			if(tests.length <= 0) {
				return SpecifiedTestsDoNotExist(arguments.specifiedTests);
			}
		}
		if(arguments.osExclusive) {
			tests = tests.filter(function(t) {
				final sysDir = test.folderNames.intendedOutput + "-" + systemName();
				return FileSystem.exists(Path.join([test.testsDirectory, t, sysDir]));
			});
		}

		// ------------------------------------
		// Output comparison tests.
		var failures = 0;
		if(arguments.buildMode != Only) {
			for(t in tests) {
				switch(doHaxeCompilationTest(t)) {
					case Ok(true): {
						// Success!
					}
					case Ok(false): {
						failures++;
					}
					case error: {
						return error.convert();
					}
				}
			}
		}

		// ------------------------------------
		// If not all comparison tests passed, exit here.
		final testCount = tests.length;
		if(failures > 0 && arguments.buildMode != Always) {
			return Ok(FailedComparisonTests(failures, testCount));
		}

		// ------------------------------------
		// Check if we should build.
		if(arguments.buildMode == Never) {
			return Ok(NeverBuild);
		}

		failures = 0;
		final systemName = systemName();
		final originalCwd = Sys.getCwd();

		Sys.println("\n===========\nBuilding Tests\n===========\n");

		// ------------------------------------
		// Check platform.
		// TODO: Let users configure which platforms are supported.
		if(systemName != "Windows" && systemName != "Linux" && systemName != "Mac") {
			return UnsupportedPlatform(systemName);
		}

		// ------------------------------------
		// Build and execute tests.
		final failedTests = [];
		for(t in tests) {
			switch(doBuildAndExecutionTest(
				t,
				systemName,
				originalCwd
			)) {
				case Ok(_): {}
				case error: {
					failures++;
					failedTests.push(t);
				}
			}
		}

		// ------------------------------------
		// If not all build tests passed, exit here.
		if(failures > 0) {
			return Ok(FailedBuildOrExecuteTests(failedTests, testCount));
		}

		// ------------------------------------
		// Success!!
		return Ok(PassedTests(testCount));
	}

	/**
		Get the platform name.
	**/
	function systemName() {
		return arguments.simulatePlatform ?? Sys.systemName();
	}

	/**
		Calls `printlnErr`, but also prefixes it with a cute "failed" message.
	**/
	function printFailed(msg: Null<String> = null) {
		printlnErr("Failed... 💔");
		if(msg != null) {
			printlnErr(msg);
		}
	}

	/**
		Test directory could not be found.
	**/
	function checkAndReadDir(path: String): Error<Array<String>> {
		if(!FileSystem.exists(path)) {
			return DirectoryCouldNotBeFound(path);
		}
		return Ok(FileSystem.readDirectory(path));
	}

	/**
		Runs the test for directory `testDirectory` that compiles the Haxe code and checks
		to see if the output is what's expected.
	**/
	function doHaxeCompilationTest(testDirectory: String): Error<Bool> {
		Sys.println("-- " + testDirectory + " --");
		final testDir = Path.join([test.testsDirectory, testDirectory]);
		final hxmlFiles = switch(checkAndReadDir(testDir)) {
			case Ok(files): files;
			case error: return error.convert();
		}
		final hxmlFiles = hxmlFiles.filter(function(file) {
			final p = new Path(file);
			return p.ext == "hxml";
		});
		return if(hxmlFiles.length == 0) {
			printFailed("No .hxml files found in test directory: `" + testDir + "`!");
			Ok(false);
		} else {
			Ok(runHaxeCompilationCommand(testDir, hxmlFiles));
		}
	}

	/**
		Executes the Haxe compilation command and handles its results.
	**/
	function runHaxeCompilationCommand(testDir: String, hxmlFiles: Array<String>): Bool {
		final noIntended = FileSystem.exists(Path.join([testDir, "no-intended"]));

		for(hxml in hxmlFiles) {
			final absPath = Path.join([testDir, hxml]);
			final args = test.generateHaxeCompilationArguments(
				Path.join([testDir, noIntended ? test.folderNames.output : getOutputDirectory(testDir)]),
				testDir,
				{ name: hxml, absolutePath: absPath },
				arguments,
			);

			Sys.println("haxe " + args.join(" "));
			Sys.println("");

			final process = new Process("haxe " + args.join(" "));
			final _out = process.stdout.readAll();
			final _in = process.stderr.readAll();

			final stdoutContent = _out.toString();
			final stderrContent = _in.toString();

			final ec = process.exitCode();
			if(ec != 0) {
				onHaxeCompilationFail(process, hxml, ec, stdoutContent, stderrContent);
				return false;
			} else {
				if(stdoutContent.length > 0) {
					Sys.println(stdoutContent);
				}
				if(arguments.showAllOutput && stderrContent.length > 0) {
					Sys.println(stderrContent);
				}
			}
		}

		return if(noIntended) {
			Sys.println("No intended folder! 😉");
			true;
		} else if(compareOutputFolders(testDir)) {
			Sys.println("Success! Output matches! ❤️");
			true;
		} else {
			false;
		}
	}

	/**
		Returns a path to the output folder the Haxe compilation should build to.
		This can change depending on platform or if a user is updating the intended content.
	**/
	function getOutputDirectory(testDir: String): String {
		final sysDir = test.folderNames.intendedOutput + "-" + systemName();
		return if(arguments.updateIntendedSys) {
			sysDir;
		} else if(arguments.updateIntended) {
			if(FileSystem.exists(Path.join([testDir, sysDir]))) {
				sysDir;
			} else {
				test.folderNames.intendedOutput;
			}
		} else {
			test.folderNames.output;
		}
	}

	/**
		Called when the Haxe compilation process returns a non-zero exit code.
		Prints information to help diagnose the problem.
	**/
	function onHaxeCompilationFail(process: Process, hxml: String, ec: Int, stdoutContent: String, stderrContent: String) {
		final info = [];
		info.push(".hxml File:\n" + hxml);
		info.push("Exit Code:\n" + ec);

		if(stdoutContent.length > 0) {
			info.push("Output:\n" + stdoutContent);
		}

		if(stderrContent.length > 0) {
			info.push("Error Output:\n" + stderrContent);
		}

		var result = "\nFAILURE INFO\n------------------------------------\n";
		result += info.join("\n\n");
		result += "\n------------------------------------\n";

		printFailed(result);
	}

	/**
		Checks if the contents of the output and intended folders are the same.
		If they are, `true` is returned.
	**/
	function compareOutputFolders(testDir: String): Bool {
		final outFolder = Path.join([testDir, test.folderNames.output]);
		final intendedFolderSys = Path.join([testDir, test.folderNames.intendedOutput + "-" + systemName()]);

		final intendedFolder = if(FileSystem.exists(intendedFolderSys)) {
			intendedFolderSys;
		} else {
			Path.join([testDir, test.folderNames.intendedOutput]);
		}

		if(!FileSystem.exists(intendedFolder)) {
			printFailed("Intended folder does not exist? Looking for: " + intendedFolder);
			return false;
		}

		final files = getAllFiles(intendedFolder);
		final errors = [];
		for(f in files) {
			final intendedPath = Path.join([intendedFolder, f]);
			final outPath = Path.join([outFolder, f]);
			final err = compareFiles(intendedPath, outPath);
			if(err != null) {
				// If updating the intended folder, copy changes to the out/ as well.
				if(arguments.updateIntended) {
					if(!FileSystem.exists(intendedPath)) {
						FileSystem.deleteFile(outPath);
					} else {
						final dir = Path.directory(outPath);
						if(!FileSystem.exists(dir)) {
							FileSystem.createDirectory(dir);
						}
						sys.io.File.saveContent(outPath, sys.io.File.getContent(intendedPath));
					}
				} else {
					errors.push(err);
				}
			}
		}

		// If updating the intended folder, delete any out/ files that don't match.
		if(arguments.updateIntended) {
			final outputFiles = getAllFiles(outFolder);
			for(f in outputFiles) {
				if(!files.contains(f)) {
					final path = Path.join([outFolder, f]);
					if(FileSystem.exists(path)) {
						FileSystem.deleteFile(path);
					}
				}
			}
		}

		return if(errors.length > 0) {
			var result = "\nOUTPUT DOES NOT MATCH\n------------------------------------\n";
			result += errors.join("\n");
			result += "\n------------------------------------\n";
			printFailed(result);
			false;
		} else {
			true;
		}
	}

	/**
		Gets a recursive list of all files in the directory and subdirectories.
	**/
	function getAllFiles(dir: String): Array<String> {
		final result = [];
		for(file in FileSystem.readDirectory(dir)) {
			final fullPath = Path.join([dir, file]);
			if(FileSystem.isDirectory(fullPath)) {
				for(f in getAllFiles(fullPath)) {
					result.push(Path.join([file, f]));
				}
			} else {
				result.push(file);
			}
		}
		return result;
	}

	/**
		Compares the contents of two files.
		If they are identical, `null` is returned.
		If not identical, the reason is provided as a `String`.
	**/
	function compareFiles(fileA: String, fileB: String): Null<String> {
		if(!FileSystem.exists(fileA)) {
			return "`" + fileA + "` does not exist.";
		}
		if(!FileSystem.exists(fileB)) {
			return "`" + fileB + "` does not exist.";
		}

		function normalize(s: String) return StringTools.trim(StringTools.replace(s, "\r\n", "\n"));

		final contentA = normalize(sys.io.File.getContent(fileA));
		final contentB = normalize(sys.io.File.getContent(fileB));

		if(contentA != contentB) {
			final msg = fileB + "` does not match the intended output.";

			return if(arguments.noDetails) {
				msg;
			} else {
				final result = ["---\n`" + msg + "\n---"];

				final linesA = contentA.split("\n");
				final linesB = contentB.split("\n");

				for(i in 0...linesA.length) {
					if(linesA[i] != linesB[i]) {
						var comp = "* Line " + (i + 1) + "\n";
						comp += "[int] (" + linesA[i].length + ") `" + linesA[i] + "`\n";
						comp += "[out] (" + (linesB[i]?.length ?? 0) + ") `" + (i < linesB.length ? linesB[i] : "<empty>") + "`";
						result.push(comp);
					}
				}

				if(linesB.length > linesA.length) {
					result.push(fileB + " also has " + (linesB.length - linesA.length) + " more lines than " + fileA + ".");
				}

				result.join("\n\n");
			}
		}

		return null;
	}

	/**
		Builds and executes the output from Haxe.
	**/
	function doBuildAndExecutionTest(
		testDirectory: String,
		systemName: String,
		originalCwd: String,
	): Error<{
		buildOutput: Output,
		executionOutput: Output
	}> {
		Sys.println("-- " + testDirectory + " --");

		final testDir = Path.join([test.testsDirectory, testDirectory]);
		final buildDir = Path.join([testDir, test.folderNames.build]);

		if(!FileSystem.exists(buildDir)) {
			FileSystem.createDirectory(buildDir);
		}

		Sys.println("cd " + buildDir);
		Sys.setCwd(buildDir);

		final compileCommand = test.generateBuildCommand(
			test.folderNames.output,
			buildDir,
			testDir,
			arguments,
		);

		final result: Error<{ buildOutput: Output, executionOutput: Output }> = if(compileCommand != null) {
			Sys.println(compileCommand);
			Sys.println("");

			final compileProcess = new Process(compileCommand);

			final stdoutContent = compileProcess.stdout.readAll().toString();
			final stderrContent = compileProcess.stderr.readAll().toString();
			final ec = compileProcess.exitCode();
			compileProcess.close();

			final buildOutput = [stdoutContent, stderrContent];

			if(ec != 0) {
				BuildFailed(buildOutput);
			} else {
				final executeProcessCommand = test.generateExecuteCommand(
					test.folderNames.output,
					buildDir,
					testDir,
					arguments,
				);

				if(executeProcessCommand != null) {
					final executeProcess = new Process(executeProcessCommand);
					final exeOut = executeProcess.stdout.readAll().toString();
					final exeErr = executeProcess.stderr.readAll().toString();
					final exeEc = executeProcess.exitCode();
					final executionOutput = [exeOut, exeErr];
					if(exeEc != 0) {
						ExecutionFailed(buildOutput, executionOutput, exeEc);
					} else {
						Ok({
							buildOutput: buildOutput,
							executionOutput: executionOutput,
						});
					}
				} else {
					Ok({
						buildOutput: buildOutput,
						executionOutput: ["", ""],
					});
				}
			}
		} else {
			Ok({
				buildOutput: ["", ""],
				executionOutput: ["", ""],
			});
		}

		// Reset to original current working directory
		Sys.setCwd(originalCwd);

		return result;
	}
}

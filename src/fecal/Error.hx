package fecal;

@:using(fecal.Error.ErrorExt)
enum Error<T> {
	Ok(result: T);
	DirectoryCouldNotBeFound(path: String);
	UnsupportedPlatform(platform: String);
	SpecifiedTestsDoNotExist(tests: Array<String>);
	BuildFailed(output: Output);
	ExecutionFailed(buildOutput: Output, executionOutput: Output, exitCode: Int);
}

class ErrorExt {
	public static function convert<T, U>(self: Error<T>): Error<U> {
		return switch(self) {
			case Ok(_): throw "Cannot convert non-error data.";
			case DirectoryCouldNotBeFound(path): DirectoryCouldNotBeFound(path);
			case UnsupportedPlatform(platform): UnsupportedPlatform(platform);
			case SpecifiedTestsDoNotExist(tests): SpecifiedTestsDoNotExist(tests);
			case BuildFailed(output): BuildFailed(output);
			case ExecutionFailed(buildOutput, executionOutput, exitCode): ExecutionFailed(buildOutput, executionOutput, exitCode);
		}
	}
}

package fecal;

import fecal.data.Output;

/**
	Represents either a valid value or any possible error within Fecal.
**/
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
	/**
		Given an `fecal.Error` that is not `Ok`, converts the generic type to another.
		Since the generic type is only used in `Ok`, this does not perform any conversion.
	**/
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

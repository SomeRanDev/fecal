package fecal.data;

/**
	The data passed to the `generateExecuteCommand` argument callback for `fecal.Fecal.test`.
**/
typedef GenerateExecuteCommandData = {
	outputDirectory: String,
	buildDirectory: String,
	testDirectory: String,
	arguments: Arguments,
}

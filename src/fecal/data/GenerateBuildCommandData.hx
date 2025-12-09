package fecal.data;

/**
	The data passed to the `generateBuildCommand` argument callback for `fecal.Fecal.test`.
**/
typedef GenerateBuildCommandData = {
	outputDirectory: String,
    buildDirectory: String,
	testDirectory: String,
	arguments: Arguments,
}

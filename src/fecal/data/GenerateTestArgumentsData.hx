package fecal.data;

/**
	The data passed to the `generateTestArguments` argument callback for `fecal.Fecal.test`.
**/
typedef GenerateTestArgumentsData = {
	outputDirectory: String,
	testDirectory: String,
	hxmlFile: {
		name: String,
		absolutePath: String
	},
	arguments: Arguments,
}

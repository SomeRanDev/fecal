package fecal.tester;

/**
    The result of `fecal.Tester.run`.
**/
enum TesterResult {
    PassedTests(testCount: Int);
	FailedComparisonTests(failureCount: Int, testCount: Int);
	FailedBuildOrExecuteTests(failures: Array<String>, testCount: Int);
	PrintedHelp;
	NeverBuild;
}

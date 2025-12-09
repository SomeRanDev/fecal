package fecal;

@:structInit
class Arguments {
	public var help(default, null) = false;

	public var showAllOutput(default, null) = false;
	public var updateIntended(default, null) = false;
	public var updateIntendedSys(default, null) = false;
	public var osExclusive(default, null) = false;
	public var noDetails(default, null) = false;
	public var buildOnly(default, null) = false;
	public var alwaysBuild(default, null) = false;
	public var neverBuild(default, null) = false;
	public var simulatePlatform(default, null): Null<String> = null;
	public var specifiedTests(default, null): Null<Array<String>> = null;

	/**
		Generates an instance of `Arguments` with the arguments from `Sys.args`.
	**/
	public static function initFromArgs(): Arguments {
		final args = Sys.args();

		if(args.contains("--help")) {
			return {
				help: true,
			};
		}

		var showAllOutput = args.contains("--show-output");
		var updateIntended = args.contains("--update-intended");
		var updateIntendedSys = args.contains("--update-intended-sys");
		var osExclusive = args.contains("--os-exclusive");
		var noDetails = args.contains("--no-details");
		var buildOnly = args.contains("--build-only");
		var alwaysBuild = args.contains("--always-build");
		var neverBuild = args.contains("--never-build");
		var simulatePlatform: Null<String> = null;

		if(args.contains("--dev-mode")) {
			alwaysBuild = true;
			showAllOutput = true;
			noDetails = true;
		}

		// ------------------------------------
		// Simulate platform
		// ------------------------------------
		for(a in args) {
			if(StringTools.startsWith(a, "--simulate=")) {
				final r = ~/^simulate=(\w+)$/;
				if(r.match(a)) {
					simulatePlatform = r.matched(1);
					break;
				}
			}
		}

		// ------------------------------------
		// Specified tests
		// ------------------------------------
		final specifiedTests = args.map(a -> {
			final r = ~/\-\-test=(\w+)/;
			if(r.match(a)) {
				r.matched(1);
			} else {
				null;
			}
		}).filter(a -> a != null);

		return {
			showAllOutput: showAllOutput,
			updateIntended: updateIntended,
			updateIntendedSys: updateIntendedSys,
			osExclusive: osExclusive,
			noDetails: noDetails,
			buildOnly: buildOnly,
			alwaysBuild: alwaysBuild,
			neverBuild: neverBuild,
			simulatePlatform: simulatePlatform,
			specifiedTests: specifiedTests.length == 0 ? null : specifiedTests,
		}
	}
}

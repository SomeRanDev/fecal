package fecal.data;

/**
	The mode parsed from `--build=[only|always|never]`.
**/
enum BuildMode {
	Default;
	Only;
	Always;
	Never;
}

/**
	Used to parse and store command line arguments.
**/
@:structInit
class Arguments {
	public var help(default, null) = false;

	public var showAllOutput(default, null) = false;
	public var updateIntended(default, null) = false;
	public var updateIntendedSys(default, null) = false;
	public var osExclusive(default, null) = false;
	public var noDetails(default, null) = false;
	public var buildMode(default, null): BuildMode = Default;
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
		var simulatePlatform: Null<String> = null;

		// ------------------------------------
		// Build mode
		// ------------------------------------
		var buildMode = Default;
		for(a in args) {
			if(StringTools.startsWith(a, "--build=")) {
				final r = ~/^build=(\w+)$/;
				if(r.match(a)) {
					buildMode = stringToBuildMode(r.matched(1));
					break;
				}
			}
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

		// ------------------------------------
		// Dev Mode
		// TODO: This seems kinda random, remove?
		// ------------------------------------
		if(args.contains("--dev-mode")) {
			buildMode = Always;
			showAllOutput = true;
			noDetails = true;
		}

		return {
			showAllOutput: showAllOutput,
			updateIntended: updateIntended,
			updateIntendedSys: updateIntendedSys,
			osExclusive: osExclusive,
			noDetails: noDetails,
			buildMode: buildMode,
			simulatePlatform: simulatePlatform,
			specifiedTests: specifiedTests.length == 0 ? null : specifiedTests,
		}
	}

	static function stringToBuildMode(s: String) {
		return switch(s.toLowerCase()) {
			case "only": Only;
			case "always": Always;
			case "never": Never;
			case _: Default;
		}
	}
}

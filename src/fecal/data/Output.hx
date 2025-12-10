package fecal.data;

/**
    Represents an `Array<String>` of length `2`.
    The first element is the `stdout`, and the second is `stderr`.
**/
abstract Output(Array<String>) {
	function new(a: Array<String>) {
		this = a;
	}

	@:from
	public static function from(output: Array<String>): Output {
		if(output.length != 2) {
			throw "Output must be an array of size 2.";
		}
		return new Output(output);
	}

	public function stdout(): String {
		return this[0];
	}

	public function stderr(): String {
		return this[1];
	}
}

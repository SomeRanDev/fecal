package fecal;

/**
	Prints to `stderr`.
**/
function printlnErr(msg: String) {
	Sys.stderr().writeString(msg + "\n", haxe.io.Encoding.UTF8);
	Sys.stderr().flush();
}
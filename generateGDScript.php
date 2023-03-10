<?php
/* This was made to automate some code generation for GDScript.
 * The idea being you can have a script be generated with certain features removed from the source rather than ignored during runtime.
 * As GDScript is a kinda slow and interpreted language, this will hopefully improve runtime without sacrifing optional functionality.
 * WIP/TODO A lot.
//*/
//Debugging Code
$debug_mode = false;
function printd(string $s, string $prefix="[DEBUG]: ", string $suffix="\n") : bool
{
	global $debug_mode;
	if($debug_mode)
	{
		print($prefix . $s . $suffix);
	}
	return $debug_mode;
}
if($debug_mode)
{
	// Show all errors
	error_reporting(E_ALL);
}
printd("Script has started.");

//Global Variables
$default_prefix = "DEFAULT_";
$json = "";
$json_data = array();

//!TODO
//The meaning of these flags are/should be script/json specific.
$script_mode           = 0b0000000000000000;//uint16
$FLAG_DISABLE_ALL      = 0b1111111111111111;
$FLAG_DISABLE_DEBUG    = 0b0000000000000001;
$FLAG_DISABLE_ROTATION = 0b0000000000000010;
$FLAG_DISABLE_MOTION   = 0b0000000000000100;
$FLAG_DISABLE_COLLISION= 0b0000000000001000;
$FLAG_DISABLE_LERP     = 0b0000000000010000;
$FLAG_DISABLE_LIMITS   = 0b0000000000100000;
$FLAG_DISABLE_MOUSE    = 0b0000000001000000;

//Functions
function is_mode( int $test_mode ) : bool
{
	//!TODO
	//Returns true if the mode of the script matches the mode provided via parameter.
	//Used to enable/include vs disable/exclude parts of the script during generation.
	return true;
}
//Methods
function print_comment(string $hc)
{
	print("#" . $hc . "\n");
}
function print_tooltip_comments(array $a)
{
	//Prints tooltip for exported variables. Prints normal comments for non-exported variables and constants.
	if(empty($a))
	{
		//Used for manual formatting.
		return;
	}
	if(!isset($a["tooltip"]))
	{
		//Nothing to print.
		return;
	}
	$prefix = "";
	if(isset($a["export"]))
	{
		$prefix = $a["export"] ? "## " : "# ";
	}
	else
	{
		//Is a normal comment.
		$prefix = "# ";
	}
	foreach($a["tooltip"] as $i => $next)
	{
		print($prefix . $next . "\n");
	}
}
function print_constant(array $c)
{
	//Format:
	//{"tooltip":[],"name":"example_constant","type":"float","value":"PI","modes":0}
	if(empty($c))
	{
		//Empty/Null Arrays can be used for manual spacing.
		print("\n");
		return;
	}
	if($c["name"] == null or $c["value"] == null)
	{
		printd("Failed to print constant value. Array had undefined name or value.", "[WARN]: ");
		return;
	}
	print_tooltip_comments($c);
	print("const " . strtoupper($c["name"]));
	if($c["type"])
	{
		print(":" . $c["type"]);
	}
	print(" = " . $c["value"]);
	if(isset($c["comment"]))
	{
		print_comment($c["comment"]);
	}
	else
	{
		print("\n");
	}
}
function print_variable(array $v)
{
	global $default_prefix;
	//Format:
	//{"tooltip":[],"export":true,"name":"example_variable","type":"float","value":"PI","modes":0,"generate_default":true,"setget":"function_name"}
	//Validate inputs
	if($v == null)
	{
		//Used for manual formatting.
		print("\n");
		return;
	}
	if($v["export"] == null){ $v["export"] = false; }
	if($v["name"] == null or strlen($v["name"]) <= 0)//Warning: strlen(null) is deprecated.
	{
		printd("Failed to print variable. Variable name was undefined or empty.", "[WARN]: ");
		return;
	}
	if(!isset($v["generate_default"])){ $v["generate_default"] = false; }
	//Print tooltip(if needed.)
	print_tooltip_comments($v);
	//Print it.
	if($v["export"])
	{
		print("export");
		if($v["type"])
		{
			print("(" . $v["type"] . ")");
		}
		print(" ");
	}
	print("var " . $v["name"]);
	if($v["type"])
	{
		print(":" . $v["type"]);
	}
	if($v["value"])
	{
		print(" = ");
		if($v["generate_default"] == false)
		{
			print($v["value"]);
		}else{
			print("DEFAULT_" . strtoupper($v["name"]));
		}
	}
	if(isset($v["setget"])){ print(" setget " . $v["setget"]); }
	if(isset($v["comment"]))
	{
		print_comment($v["comment"]);
	}
	else
	{
		print("\n");
	}
}
function preprocess_variable_constants(array $variables)
{
	global $default_prefix, $json_data;
	//Adds any auto-defined default constant values from variables array to constants array.
	//Assumes json_data is loaded and valid.
	foreach($variables as $i => $next)
	{
		if(!isset($next["name"]))
		{
			array_push($json_data["constants"], array());//For manual formatting.
			continue;
		}
		if(isset($next["generate_default"]))
		{
			if(!$next["generate_default"]) continue;
			array_push($json_data["constants"], array(
			"name" => $default_prefix . $next["name"],
			"type" => $next["type"],
			"value" => $next["value"]
			));
		}
	}
}
function print_function(array $f)
{
	//Prints a GDScript function from array
	$temp_flag = false;
	$temp_count = 0;
	if($f == null)
	{
		//Used for manual formatting.
		print("\n");
		return;
	}
	if($f["name"] == null or strlen($f["name"]) <= 0)//Warning: strlen(null) is deprecated.
	{
		printd("Failed to print function. Function name was undefined or empty.", "[WARN]: ");
		return;
	}
	print("func " . strtolower($f["name"]) . "(");
	if(isset($f["parameters"]))
	{
		$temp_count = count($f["parameters"]);
		if($temp_count > 0)
			$temp_flag = true;
	}
	if($temp_flag)
	{
		foreach($f["parameters"] as $i => $next)
		{
			print($next);
			if(($i + 1) < $temp_count)
				print(", ");
		}
	}
	$temp_flag = false;
	$temp_count = 0;
	print(")");
	if(isset($f["type"]))
	{
		print(" -> " . $f["type"]);
	}
	print(":\n");
	if(isset($f["code"]))
	{
		if(count($f["code"]) > 0)
			$temp_flag = true;
	}
	if($temp_flag)
	{
		foreach($f["code"] as $i => $next)
			print("\t" . $next . "\n");
	} else {
		print("\tpass\n");
	}
	$temp_flag = false;
}
function print_script( $json_data, $script_mode = 0 )
{
	//Processes and prints a GDScript from json_data
	//Pre-Processing
	preprocess_variable_constants($json_data["variables"]);
	//Print Header Comments
	if(isset($json_data["header_comments"]))
	{
		foreach($json_data["header_comments"] as $i => $next)
		{
			print_comment($next);
		}
		print("\n");
	}
	//Print Constants
	if(isset($json_data["constants"]))
	{
		print("########################\n");
		print("# Constants / Defaults #\n");
		print("########################\n");
		foreach($json_data["constants"] as $i => $next)
		{
			print_constant($next);
		}
		print("\n");
	}
	//Print Variables
	if(isset($json_data["variables"]))
	{
		print("##################################\n");
		print("# Variables / Exported Variables #\n");
		print("##################################\n");
		foreach($json_data["variables"] as $i => $next)
		{
			print_variable($next);
		}
		print("\n");
	}
	//Functions/Methods
	if(isset($json_data["functions"]))
	{
		print("####################################################\n");
		print("# Functions / Methods / Events / Signals / SetGets #\n");
		print("####################################################\n");
		foreach($json_data["functions"] as $i => $next)
		{
			print_function($next);
		}
		print("\n");
	}
}
function load_json( string $file_path )
{
	//Attempts to read json from file, decode, and then return value.
	// Read the JSON file.
	$json = file_get_contents('./Script.json');
	if($json == false)
	{
		printd("load_json() Failed to read script file.");
		return null;
	} else {
		printd("load_json() Finished reading in the raw JSON file.");
	}
	// Decode the JSON file
	return(json_decode($json, true, 512));
}

// Start main execution.
$json_data = load_json('./Script.json');
if($json_data == null)
{
	printd("Failed to parse JSON data.");
	die();
}
// Display data(Debugging)
if($debug_mode){ printd("Parsed JSON recursive value: "); print_r($json_data); }
// Print
print_script($json_data);
//Finish
printd("Script has stopped.");
?>

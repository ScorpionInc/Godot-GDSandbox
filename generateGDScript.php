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

//Functions
function is_mode( int $test_mode ) : bool
{
	//!TODO
	//Returns true if the mode of the script matches the mode provided via parameter.
	//Used to enable/include vs disable/exclude parts of the script during generation.
	return true;
}
//Methods
function print_header_comment(string $hc)
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
	print(" = " . $c["value"] . "\n");
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
	print("\n");
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
			array_push($json_data["constants"], array(
			"name" => $default_prefix . $next["name"],
			"type" => $next["type"],
			"value" => $next["value"]
			));
		}
	}
}

// Start main execution.
// Read the JSON file 
$json = file_get_contents('./Script.json');
if($json == false)
{
	printd("Failed to read script file.");
}
else
{
	printd("Finished reading in the raw JSON file.");
}
// Decode the JSON file
$json_data = json_decode($json, true, 512);
if($json_data == null)
{
	printd("Failed to parse JSON data.");
	die();
}
// Display data(Debugging)
if($debug_mode){ printd("Parsed JSON recursive value: "); print_r($json_data); }

//Pre-Processing
preprocess_variable_constants($json_data["variables"]);

//Print Header Comments
foreach($json_data["header_comments"] as $i => $next)
{
	print_header_comment($next);
}
print("\n");

//Print Constants
print("#####################\n");
print("#Constants / Defaults\n");
print("#####################\n");
foreach($json_data["constants"] as $i => $next)
{
	print_constant($next);
}
print("\n");

//Print Variables
print("###############################\n");
print("#Variables / Exported Variables\n");
print("###############################\n");
foreach($json_data["variables"] as $i => $next)
{
	print_variable($next);
}
print("\n");

//!TODO Functions/Methods/Events/Signals/SetGets/ect.

//Finish
printd("Script has stopped.");
?>

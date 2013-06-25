
var FILE = require("file"),
    ENV  = require("system").env,
    Jake = require("jake"),
    task = Jake.task,
    FileList = Jake.FileList,
    bundle = require("objective-j/jake").bundle,
    framework = require("objective-j/jake").framework,
    environment = require("objective-j/jake/environment");

$CONFIGURATION = ENV['CONFIG'] || "Release";

$BUILD_DIR = ENV['CAPP_BUILD'] || ENV['STEAM_BUILD'];

bundle ("MapKit", function(task)
{
    task.setBuildIntermediatesPath(FILE.join($BUILD_DIR, "MapKit.build", $CONFIGURATION))
    task.setBuildPath(FILE.join($BUILD_DIR, $CONFIGURATION));

    task.setAuthor("280 North, Inc.");
    task.setEmail("feedback @nospam@ 280north.com");
    task.setSummary("Plugin framework for Atlas");
    task.setIdentifier("com.280n.MapKit");
    task.setSources(new FileList("*.j"), [environment.Browser, environment.CommonJS]);
    task.setResources([]);//All the resources belong to the plugin
    task.setFlattensSources(true);

    if ($CONFIGURATION === "Release")
        task.setCompilerFlags("-O");
    else
        task.setCompilerFlags("-DDEBUG -g");
});

task ("build", ["MapKit"]);
task ("default", ["build"]);

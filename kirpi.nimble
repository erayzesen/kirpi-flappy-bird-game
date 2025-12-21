# Package
version       = "1.0.0"
author        = "Author"
description   = "your kirpi project description"
license       = "License"
srcDir        = "src"
bin           = @["game"]


# Dependencies
requires "nim >= 2.2.4"
requires "kirpi"


import std/distros
if detectOs(Windows):
 foreignDep "openjdk"
 foreignDep "wget"
elif detectOs(Ubuntu):
 foreignDep "default-jdk"

# Tasks

# mode = ScriptMode.Verbose

include "build_android.nims"
include "setup_build_env.nims"

task testCI, "Runs the test suite":
  # Test Android cross-compilation
  setupAndroidTask()
  buildAndroidTask()

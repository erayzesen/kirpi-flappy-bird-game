import os

let projectPathName=projectName()

proc createDirAll(file:string) =
    when defined(windows):
        exec "mkdir releases\\windows"
    elif defined(linux) or defined(macosx):
        exec "mkdir -p releases/linux"

const AndroidApiVersion {.intdefine.} = 33
const AndroidNdk {.strdefine.} = "/opt/android-ndk"
when buildOS == "windows":
  const AndroidToolchain = AndroidNdk / "toolchains/llvm/prebuilt/windows-x86_64"
elif buildOS == "linux":
  const AndroidToolchain = AndroidNdk / "toolchains/llvm/prebuilt/linux-x86_64"
elif buildOS == "macosx":
  const AndroidToolchain = AndroidNdk / "toolchains/llvm/prebuilt/darwin-x86_64"
const AndroidSysroot = AndroidToolchain / "sysroot"

when defined(android):
  createDirAll ("releases/android")
  --define:GraphicsApiOpenGlEs2
  --os:android
  --cc:clang
  when hostCPU == "arm":
    const AndroidTriple = "armv7a-linux-androideabi"
    const AndroidAbiFlags = "-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16"
  elif hostCPU == "arm64":
    const AndroidTriple = "aarch64-linux-android"
    const AndroidAbiFlags = "-march=armv8-a -mfix-cortex-a53-835769"
  elif hostCPU == "i386":
    const AndroidTriple = "i686-linux-android"
    const AndroidAbiFlags = "-march=i686"
  elif hostCPU == "amd64":
    const AndroidTriple = "x86_64-linux-android"
    const AndroidAbiFlags = "-march=x86-64"
  const AndroidTarget = AndroidTriple & $AndroidApiVersion

  switch("clang.path", AndroidToolchain / "bin")
  # switch("clang.exe", AndroidTarget & "-clang")
  # switch("clang.linkerexe", AndroidTarget & "-clang")
  switch("clang.cpp.path", AndroidToolchain / "bin")
  # switch("clang.cpp.exe", AndroidTarget & "-clang++")
  # switch("clang.cpp.linkerexe", AndroidTarget & "-clang++")
  switch("clang.options.always", "--target=" & AndroidTarget & " --sysroot=" & AndroidSysroot &
         " -I" & AndroidSysroot / "usr/include" &
         " -I" & AndroidSysroot / "usr/include" / AndroidTriple & " " & AndroidAbiFlags &
         " -D__ANDROID__ -D__ANDROID_API__=" & $AndroidApiVersion)
  switch("clang.options.linker", "--target=" & AndroidTarget & " -shared " & AndroidAbiFlags)

  --define:androidNDK
  # --mm:orc
  --panics:on # not strictly needed but good to have
  --define:noSignalHandler
  switch("out", "releases/android/" & projectPathName)

elif defined(emscripten):
  let htmlPath="releases/html5/" & projectPathName
  createDirAll(htmlPath)
  --define:GraphicsApiOpenGlEs2
  --define:NaylibWebResources
  switch("define", "NaylibWebResourcesPath=src/resources")
  --os:linux
  --cpu:wasm32
  --cc:clang
  when buildOS == "windows":
    --clang.exe:emcc.bat
    --clang.linkerexe:emcc.bat
    --clang.cpp.exe:emcc.bat
    --clang.cpp.linkerexe:emcc.bat
  else:
    --clang.exe:emcc
    --clang.linkerexe:emcc
    --clang.cpp.exe:emcc
    --clang.cpp.linkerexe:emcc
  
  # Set the stack size to 5MB to prevent 'memory access out of bounds' errors.
  # This often happens in release builds due to aggressive optimizations.
  # If you still encounter memory access errors, feel free to increase this value.
  --passL:"-sSTACK_SIZE=5MB"

  # Allow the heap to grow dynamically if the game needs more memory for assets.
  --passL:"-sALLOW_MEMORY_GROWTH=1"

  # Ensure the initial memory is large enough for a typical game (e.g., 32MB or 64MB).
  --passL:"-sINITIAL_MEMORY=33554432" # 32MB
  
  # --mm:orc
  --threads:off
  --panics:on
  --define:noSignalHandler

  --passL:"-sALLOW_MEMORY_GROWTH=1"
  #Performance Optimisation Flag
  --passL:"-O3"
  # Using Html Shell
  --passL:"--shell-file minshell.html"
  switch("out", htmlPath & "/index.html")

elif defined(windows):
    createDirAll("releases/windows")
    switch("out", "releases/windows/" & projectPathName)
elif defined(linux):
    createDirAll("releases/linux")
    switch("out", "releases/linux/" & projectPathName)
elif defined(macosx):
    createDirAll("releases/macos")
    switch("out", "releases/macos/" & projectPathName)


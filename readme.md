It's a template prepared for working with the [kirpi](https://github.com/erayzesen/kirpi) framework, featuring cross-platform configurations.

# For Beginners in Nim

First, you should [install Nim](https://nim-lang.org/install.html) on your platform by following the instructions on the official website. As you may know, Nim compiles your code to C first, and then to the target platform. Therefore, you need to have C compilation tools installed on your system. Fortunately, the official Nim installers already include these tools, so you don't need to do anything extra.

If you are using [VS Code](https://code.visualstudio.com/), you can install [this extension](https://marketplace.visualstudio.com/items?itemName=NimLang.nimlang) to start developing with Nim.

# How to Use the Template
It's quite simple. Click the ***Use This Template*** button in the top-right corner (or fork the repository). Then navigate to the folder where you want your project to be created and clone it using the command below.
```shell
git clone your_template_git_repo your_project_name
```
Alternatively, you can download this repository directly without using Git and start your project right away.

If you haven't installed the **kirpi** package yet, this command will also install **kirpi**, which is a dependency of the template:  
```shell
#In your project folder
nimble install --depsOnly
```

# Project Structure

The project structure is quite simple. The `src/game.nim` file is the main file that opens your window and passes your callback functions. (You can rename it if you want; the important thing is where you call the `run` command that starts the **kirpi** application.)  

You should keep your game code and assets under the `src` folder. When you build the project, a folder named `releases` will be created in the root directory, and the build outputs will be placed under platform-specific subfolders inside `releases`.  

This way, the build process stays organized, and you end up with a clean, well-structured project.



# Building the Project

When you build the project, the output will be organized in your project's root directory under `releases/[target platform]`.

## For Linux, macOS & Windows
You can compile & run your project for your current desktop platform with a single command:  
```shell
nim c -r src/game.nim
```
When your project is finished and you're ready to publish it, don't forget to use the following command to enable performance optimizations and compile in release mode instead of debug. 

```shell
nim c -r -d:release --opt:speed src/game.nim
```



## For Web (WebAssembly)
* Install the Emscripten SDK. Follow the official [Emscripten installation guide](https://emscripten.org/docs/getting_started/downloads.html).
* Then, simply run the following command:  
```shell
nim c -d:emscripten src/game.nim
```

## For Android
* Make sure to install Java JDK and `wget`, then run the following Nimble tasks in order:  
```
nimble setupBuildEnv    # Set up Android SDK and NDK for development
nimble setupAndroid     # Prepare raylib project for Android development
nimble buildAndroid     # Compile and package raylib project for Android
```
* If you want to install and launch it on your Android device:
  * Enable USB Debugging on your device, plug it into your computer, select File Transfer, accept the RSA key, and install the package with the following command:  
    ```
    nimble deploy     # Install and monitor raylib project on Android device/emulator
    ```




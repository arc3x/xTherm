# xTherm

A mac temperature monitoring and logging application

![xTherm](/doc/menu.png?raw=true "xTherm in action")

xTherm is a status menu application that displays CPU temperature on the menu bar, and the maximum recorded temperature, current fan speeds, and maximum fan speeds in the dropdown menu. Optionally logs temperatures to file.

Log files are located in ~/Documents/xTherm/

Backend powered by [SMCKit](https://github.com/beltex/SMCKit)

For contributors, all program logic is located in StatusMenuController.swift

## Usage
Option 1: Download unsigned the binary [here](https://arc3x.github.io/xTherm). You will have to right click to launch.

Option 2 (recommended): In the root directory of this project, run `make`

Option 3: Build in XCode 8 and run the executable file
  - Once open in XCode 8, open the Product menu item and select Build.
  - The default location for the built application is ~/Library/Developer/XCode/DerivedData/

## License

MIT

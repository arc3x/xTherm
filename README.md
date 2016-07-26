# xTherm

A mac temperature monitoring and logging application

![xTherm](/doc/menu.png?raw=true "xTherm in action")

xTherm runs as a status menu application that displays CPU temperature and optionally logs temperatures to file.

Log files are located in ~/Documents/xTherm/

## Usage

Option 1 (recommended): Command line compile (from src directory)
```xcodebuild -target xTherm -project xTherm.xcodeproj```

Option 2: Run directly from XCode 8

Option 3 (recommended): Build in XCode 8 and run the executable file
  - Once open in XCode 8, open the Product menu item and select Build.
  - The default location for the built application is ~/Library/Developer/XCode/DerivedData/

## License

MIT

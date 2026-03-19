# Installation & Build Guide

## Flutter SDK Location
- **Path:** `D:\flutter_sdk`
- **Executable:** `D:\flutter_sdk\bin\flutter.bat`

## Build Command
```powershell
cd Z:\formv5\ms_group_properties
[Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Java\jdk-22', 'Process')
D:\flutter_sdk\bin\flutter.bat build apk --debug
```

## Environment Setup

### JAVA_HOME
- **Required:** Yes
- **Path:** `C:\Program Files\Java\jdk-22`
- **Note:** Set in environment before running Flutter build

### Build Output
- **Debug APK Location:** `Z:\formv5\ms_group_properties\build\app\outputs\flutter-apk\app-debug.apk`

## Quick Build Command
```powershell
[Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Java\jdk-22', 'Process'); cd Z:\formv5\ms_group_properties; D:\flutter_sdk\bin\flutter.bat build apk --debug
```

## Release Build
```powershell
[Environment]::SetEnvironmentVariable('JAVA_HOME', 'C:\Program Files\Java\jdk-22', 'Process'); cd Z:\formv5\ms_group_properties; D:\flutter_sdk\bin\flutter.bat build apk --release
```

## Project Info
- **Project:** M.S. Group Properties
- **Framework:** Flutter 3.24.5
- **Dart SDK:** ^3.5.0
- **Theme:** Orange (#FF6600) & White

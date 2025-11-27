# Timer Message Plugin

A VisualNEO Win plugin that displays customizable popup messages with auto-close timers and live countdown displays.  Built with PureBasic 6.21 (x86)

## Features

- **Timed Auto-Close** - Popups automatically close after a specified duration
- **Live Countdown** - Display remaining seconds in the title or message using `{COUNTDOWN}`
- **Callback Support** - Optionally call a subroutine when the popup closes
- **Centered Display** - Popups appear centered over your application window
- **Fully Customizable** - Configure title, caption, message, button text, and duration

## Installation

1. Download `TimerMsg.dll` or `TimerMsg.nbp`
2. If you downloaded `TimerMsg.dll` then Rename it to `TimerMsg.nbp`
3. Copy `TimerMsg.nbp` to your VisualNEO Win `PlugIns` folder
4. Install the plugin to VisualNEO Win

## Usage

### Basic Example

```
PopupMessage_Show "My App" "Alert" "This will close in 5 seconds" "OK" "5" ""
```

### With Countdown Display

```
PopupMessage_Show "My App" "Closing in {COUNTDOWN} seconds" "Please wait..." "Close Now" "10" ""
```

### With Callback

```
PopupMessage_Show "My App" "Timer" "Operation complete!" "OK" "3" "MySubroutine"
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| Title | String | Window title bar text |
| Caption | String | Main caption text (supports `{COUNTDOWN}`) |
| Message | String | Message body text (supports `{COUNTDOWN}`) |
| Button Text | String | Text displayed on the close button |
| Duration | Number | Auto-close time in seconds (0 = no auto-close) |
| Callback | String | Optional subroutine to call when popup closes |

## Variables Set

- `[PopupSecondsLeft]` - Updated every second with remaining time
- `[PopupCallback]` - Contains the callback subroutine name

## Requirements

- VisualNEO Win (32-bit)
- Windows XP or later

## Building from Source

Requires PureBasic 6.21 (x86)

1. Open `TimerMsg.pb` in PureBasic IDE
2. Set compiler options:
   - Executable Format: Shared DLL
   - Target: x86 (32-bit)
3. Compile to `TimerMsg.dll`

## Creating Your Own Plugins

Want to create your own VisualNEO Win plugins with PureBasic? Check out the [PureBasic VisualNEO Win Plugin SDK](https://github.com/darbdenral/purebasic-vnw-plugin-sdk) which includes:

- Comprehensive development guide
- AI prompt templates for quick plugin creation
- Working examples (basic and advanced)
- Memory management best practices
- PureBasic language reference

## License

Freeware - Free to use in personal and commercial projects

## Author

Brad Larned

## Notes

You may see a Runtime Error 216 when exiting the VisualNEO Win IDE. This is a harmless cleanup quirk between PureBasic and VisualNEO Win and does not affect functionality or compiled applications.

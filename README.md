# Noter

A macOS menu bar app for quickly adding notes to your Obsidian vault using OpenCode's AI-powered assistance.

![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5.0-orange?style=flat&logo=swift&logoColor=orange)
![License](https://img.shields.io/badge/License-MIT-green?style=flat)

## Features

- **Quick Note Capture** - Instantly add notes to today's daily Obsidian note
- **AI-Powered** - Uses OpenCode to intelligently format and integrate your notes
- **Menu Bar Convenience** - Always accessible from your macOS menu bar
- **Configurable** - Set your Obsidian vault directory, OpenCode path, and AI model
- **Model Selection** - Choose from preset models or use a custom model identifier
- **Vault Validation** - Automatically detects valid Obsidian vaults (checks for `.obsidian` folder)
- **Cancellable Operations** - Cancel note submissions in progress with Escape key
- **Clean macOS Design** - Native-looking interface following Apple's Human Interface Guidelines
- **Expandable Output** - View OpenCode's thinking and response with collapsible panel
- **Text Selection** - Copy output easily with text selection
- **Keyboard Shortcuts** - Press `Cmd + Enter` to submit, `Escape` to cancel
- **Right-Click Quit** - Right-click the menu bar icon to quit the app
- **Dark/Light Mode** - Adapts automatically to your system appearance
- **Launch at Login** - Optionally start Noter when you log in
- **Settings Feedback** - Visual confirmation when settings are saved

## Installation

### Prerequisites

- macOS 14.0 or later
- [OpenCode](https://opencode.ai/) installed
- [Obsidian](https://obsidian.md/) vault

### Building from Source

1. Clone the repository:
```bash
git clone https://github.com/0pilatos0/noter.git
cd noter
```

2. Open in Xcode:
```bash
open noter.xcodeproj
```

3. Build and run:
- Press `Cmd + R` or click the Play button
- The app will appear in your menu bar

## Configuration

### First Launch

When you first launch Noter, you'll see an empty state prompting you to configure your settings.

### Settings Tab

1. **Click the "Settings" tab** in the popover
2. **Select Obsidian Vault**:
   - Click "Select" or "Change"
   - Navigate to your Obsidian vault folder
   - Click "Open"
   - A green "Valid" badge confirms it's an Obsidian vault (has `.obsidian` folder)
   - An orange "No .obsidian" warning appears if it's not a valid vault (you can still use it)
3. **Configure OpenCode Path** (optional):
   - Default: `/usr/local/bin/opencode`
   - If installed elsewhere, edit the path
   - A green "Found" badge confirms OpenCode is accessible
4. **Select AI Model**:
   - Choose from preset models (opencode/big-pickle, Claude, GPT-4o, etc.)
   - Or select "Custom..." and enter any model identifier
5. **Launch at Login** (optional):
   - Toggle to start Noter automatically when you log in
6. **Important**: Ensure your vault contains a `claude.md` file with instructions for OpenCode to understand your daily note format

### Example claude.md

```markdown
# OpenCode Configuration for Noter

## Daily Note Format

- Daily notes are named `YYYY-MM-DD.md` in the `Dailies/` folder
- Notes should be appended to the end of the file
- Add a timestamp in the format `HH:MM - ` before each note

## Format Example

```
- 09:30 - Morning standup
- 14:22 - Reviewed PR #123
```

## Instructions

When I ask to add a note to today's daily note:
1. Find the daily note file for the current date
2. Append the note with a timestamp
3. Ensure the note is formatted correctly
```

## Usage

### Adding a Note

1. Click the Noter icon (📝) in your menu bar
2. Type your note in the text area
3. Press `Cmd + Enter` or click "Add Note"
4. Watch the output panel for OpenCode's response
5. The note is automatically added to today's daily note

### Output Panel

- **Collapsed by default** - Click "▸ Output" to expand
- **Shows full OpenCode response** - See the AI's thinking and actions
- **Auto-scrolls** - Automatically scrolls to show latest output
- **Text selection** - Select and copy any text you need

### Right-Click Menu

Right-click the menu bar icon for quick access to:
- **Quit Noter** - Exit the application

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd + Enter` | Submit note |
| `Escape` | Cancel in-progress submission |
| `Cmd + ,` | Open/close popover (via menu bar) |

## Architecture

```
noter/
├── Models/
│   └── AppSettings.swift           # User settings model + vault validation
├── Services/
│   ├── MenuBarManager.swift        # Menu bar + popover management
│   ├── OpenCodeService.swift       # OpenCode process execution with cancellation
│   └── StorageManager.swift        # UserDefaults persistence with error handling
├── Views/
│   ├── MenuBarView.swift           # Main container with tab navigation
│   ├── NoteInputView.swift         # Note input + output panel + cancel support
│   └── SettingsView.swift          # Configuration UI with model selection
├── Assets.xcassets/                # Images and colors
├── noter.entitlements              # Sandbox permissions
└── noterApp.swift                  # App entry point
```

## Troubleshooting

### App not responding during note submission

- **Cancel button available** - Click "Cancel" or press Escape to stop a long-running operation
- **Sandbox disabled** - The app runs without sandbox to execute OpenCode
- Ensure OpenCode is installed at the configured path
- Check that your Obsidian vault path is accessible

### Output panel shows "File not found"

- Verify OpenCode is installed: `which opencode`
- Check the OpenCode path in Settings
- Update the path if OpenCode is in a non-standard location (e.g., `/opt/homebrew/bin/opencode`)

### Opencode can't find daily note

- Ensure your vault contains a `claude.md` file
- Add instructions about your daily note format and naming convention
- Make sure the file is in the root of your vault

### Right-click doesn't show quit menu

- Restart the app
- Ensure the app has proper menu bar permissions

### Settings not persisting

- Settings now show a confirmation banner when saved
- Check if the app has write permissions
- The app uses UserDefaults which should work without issues
- Try resetting: Delete UserDefaults for `pilatos.noter`

### Launch at Login not working

- Ensure the app is properly signed
- Check System Preferences > Login Items
- The app will show an error if it fails to register

## Security

The app is designed with security in mind:

- **Sandbox disabled** - Required for OpenCode execution
- **No network access** - The app doesn't make network calls directly
- **Local storage only** - Settings stored in macOS UserDefaults
- **No telemetry** - No data is sent to external servers

## Development

### Building

```bash
# Clean build
xcodebuild clean -project noter.xcodeproj

# Debug build
xcodebuild build -project noter.xcodeproj -scheme noter -configuration Debug

# Release build
xcodebuild build -project noter.xcodeproj -scheme noter -configuration Release
```

### Running

```bash
# Run the built app
open /path/to/Build/Products/Debug/noter.app

# Or use Xcode
open noter.xcodeproj
# Then press Cmd + R
```

### Code Style

- Swift 5.0
- SwiftUI for all views
- macOS AppKit for menu bar integration
- MVVM-inspired architecture with clear separation of concerns
- Follows [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)

## Contributing

Contributions are welcome! Please feel free to:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).

## Credits

- Built with [Swift](https://swift.org/)
- UI Framework: [SwiftUI](https://developer.apple.com/xcode/swiftui/)
- AI Integration: [OpenCode](https://opencode.ai/)
- Inspired by macOS menu bar utilities

## Roadmap

- [ ] Window mode toggle - Open in resizable window for more space
- [x] Custom OpenCode model selection
- [ ] Note history - View and re-use recent notes
- [ ] Multiple vaults - Switch between different Obsidian vaults
- [ ] Note templates - Predefined note formats
- [ ] Spotlight integration - Search notes from Spotlight

## FAQ

**Q: Can I use this without OpenCode?**
A: No, Noter requires OpenCode to process and add notes to your Obsidian vault.

**Q: Does this work with other note-taking apps?**
A: Currently, Noter is designed specifically for Obsidian. Support for other apps may be added in the future.

**Q: How do I uninstall Noter?**
A: Quit the app, then delete the app bundle from your Applications folder.

**Q: Is my data safe?**
A: Yes, all your data stays in your Obsidian vault. Noter only reads/writes your notes.

**Q: Can I use multiple OpenCode models?**
A: Yes! Go to Settings and select from preset models or enter a custom model identifier.

## Contact

- GitHub: [https://github.com/0pilatos0/noter](https://github.com/0pilatos0/noter)
- Issues: [https://github.com/0pilatos0/noter/issues](https://github.com/0pilatos0/noter/issues)

---

Made with ❤️ for the Obsidian community

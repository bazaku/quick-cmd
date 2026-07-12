import Foundation

public enum DefaultConfig {
    public static let json = #"""
    {
      "hotkey": { "key": "space", "modifiers": ["option"] },
      "commands": [
        {
          "name": "Quit All Apps",
          "shell": "osascript -e 'tell application \"System Events\" to set l to name of (every process whose visible is true and name is not \"Finder\")' -e 'repeat with a in l' -e 'tell application a to quit' -e 'end repeat'",
          "show": true
        },
        { "name": "Shut Down", "shell": "osascript -e 'tell application \"System Events\" to shut down'", "show": true },
        { "name": "Restart", "shell": "osascript -e 'tell application \"System Events\" to restart'", "show": true },
        { "name": "Sleep", "shell": "osascript -e 'tell application \"System Events\" to sleep'", "show": true },
        { "name": "Lock Screen", "shell": "pmset displaysleepnow", "show": true },
        { "name": "Empty Trash", "shell": "osascript -e 'tell application \"Finder\" to empty trash'", "show": true }
      ]
    }
    """#

    public static var config: Config {
        // Force-try is safe: `json` is a compile-time constant verified by tests.
        try! JSONDecoder().decode(Config.self, from: Data(json.utf8))
    }
}

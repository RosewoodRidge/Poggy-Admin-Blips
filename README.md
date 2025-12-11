# Poggy Admin Blips

A RedM resource that allows administrators to see all player locations on the map in real-time.

## Features

- **Real-time player tracking** - See all players on the map with their server ID and character name
- **Configurable update interval** - Adjust how frequently blip positions update
- **Name whitelist support** - Optionally restrict to specific Steam display names
- **Admin group support** - Falls back to VORP admin groups when no whitelist is configured
- **Customizable blip appearance** - Change the style, sprite, and color of blips
- **Toggle visibility** - Admins can show/hide blips with a command
- **Hide own blip** - Option to hide your own blip from yourself

## Installation

1. Place the `poggy_admin_blips` folder in your server's resources directory
2. Add `ensure poggy_admin_blips` to your `server.cfg`
3. Configure the settings in `config.lua` to your preferences
4. Restart your server

## Dependencies

- [vorp_core](https://github.com/VORPCORE/vorp-core-lua)

## Configuration

All configuration options are located in `config.lua`:

### Shared Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Config.DEBUG` | boolean | `false` | Enable debug logging to console |

### Server Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Config.UPDATE_INTERVAL` | number | `500` | How often to update blip positions (milliseconds) |
| `Config.PENDING_RETRY_INTERVAL` | number | `5000` | How often to retry players who aren't fully loaded (milliseconds) |
| `Config.ADMIN_GROUPS` | table | `{"admin", "superadmin"}` | VORP groups that can see blips (used when `ALLOWED_NAMES` is empty) |

### Client Settings

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Config.ALLOWED_NAMES` | table | `{}` | Steam display names that can see blips. If empty, uses `ADMIN_GROUPS` instead |
| `Config.BLIP_STYLE` | string | `"BLIP_STYLE_ENEMY"` | The blip style hash |
| `Config.BLIP_SPRITE` | string | `"blip_ambient_companion"` | The blip sprite/icon |
| `Config.BLIP_MODIFIER` | string | `"BLIP_MODIFIER_DEBUG_GREEN"` | The blip color modifier |
| `Config.BLIP_NAME_FORMAT` | string | `"{id} \| {name}"` | Format for blip names. Use `{id}` and `{name}` as placeholders |
| `Config.HIDE_OWN_BLIP` | boolean | `true` | Hide your own blip from yourself |
| `Config.INIT_WAIT_TIME` | number | `5000` | Wait time before registering (milliseconds) |

## Commands

| Command | Description |
|---------|-------------|
| `/ahb` | Toggle admin blips on/off (admin only) |

## Usage Examples

### Restrict to specific players only

```lua
Config.ALLOWED_NAMES = {
    "PlayerName1",
    "PlayerName2"
}
```

### Allow all admins/superadmins

```lua
Config.ALLOWED_NAMES = {}  -- Empty table = use ADMIN_GROUPS
Config.ADMIN_GROUPS = {
    "admin",
    "superadmin",
    "moderator"  -- Add more groups as needed
}
```

### Change blip color to red

```lua
Config.BLIP_MODIFIER = "BLIP_MODIFIER_DEBUG_RED"
```

### Custom blip name format

```lua
Config.BLIP_NAME_FORMAT = "[{id}] {name}"  -- Shows as: [1] John Smith
```

## Blip Modifiers (Colors)

- `BLIP_MODIFIER_DEBUG_GREEN` - Green
- `BLIP_MODIFIER_DEBUG_RED` - Red
- `BLIP_MODIFIER_DEBUG_BLUE` - Blue
- `BLIP_MODIFIER_DEBUG_YELLOW` - Yellow

## Troubleshooting

### Blips not appearing

1. Enable debug mode: Set `Config.DEBUG = true` in `config.lua`
2. Check server console for debug messages
3. Verify your Steam name matches exactly (case-sensitive) if using `ALLOWED_NAMES`
4. Ensure your VORP group is in `ADMIN_GROUPS` if not using whitelist

### Blips updating slowly

Decrease `Config.UPDATE_INTERVAL` for faster updates (increases network traffic)

## Credits

- **Author:** Poggy
- **Version:** 1.0.0

## License

This resource is provided as-is for use on RedM servers.

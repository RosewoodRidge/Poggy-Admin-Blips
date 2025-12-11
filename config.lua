Config = {}

--================================--
--       SHARED CONFIGURATION     --
--================================--

-- Debug: Set to true to enable debug logging
Config.DEBUG = false

--================================--
--       SERVER CONFIGURATION     --
--================================--

-- Update interval: How often to send blip updates to admins (milliseconds)
Config.UPDATE_INTERVAL = 500

-- Pending player retry interval (milliseconds)
Config.PENDING_RETRY_INTERVAL = 5000

-- Admin groups: Which groups can see blips (used when ALLOWED_NAMES is empty)
Config.ADMIN_GROUPS = {
    "admin",
    "superadmin"
}

--================================--
--       CLIENT CONFIGURATION     --
--================================--

-- Whitelist: Only these Steam Names (Display Names) can see blips
-- If empty, all players in ADMIN_GROUPS will see blips
Config.ALLOWED_NAMES = {
    "Soup",
    "Poggy"
}

-- Blip appearance
Config.BLIP_STYLE = "BLIP_STYLE_ENEMY"              -- Style hash for creating the blip
Config.BLIP_SPRITE = "blip_ambient_companion"       -- Sprite/icon for the blip
Config.BLIP_MODIFIER = "BLIP_MODIFIER_DEBUG_GREEN"  -- Color modifier (green)

-- Blip name format: Use {id} and {name} as placeholders
Config.BLIP_NAME_FORMAT = "{id} | {name}"

-- Hide own blip: Set to true to hide your own blip from yourself
Config.HIDE_OWN_BLIP = true

-- Initial wait time before registering (milliseconds)
Config.INIT_WAIT_TIME = 5000

--================================--
--      END CONFIGURATION         --
--================================--

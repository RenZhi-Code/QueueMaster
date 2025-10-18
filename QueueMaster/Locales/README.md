# QueueMaster Localisation

This folder contains localisation files for QueueMaster addon.

## Structure

- **Locales.lua** - Core localisation system with English (enUS/enGB) default strings
- **frFR.lua** - French localisation
- **deDE.lua** - German localisation
- **esES.lua** - Spanish localisation (includes esMX)
- **embeds.xml** - XML file that loads all localisation files

## How Localisation Works

1. The core `Locales.lua` file defines all strings in English and creates the `QueueMaster.L` table
2. Language-specific files (e.g., `frFR.lua`) override English strings with translations
3. Only the file matching the client's locale is executed (checked via `GetLocale()`)
4. If a translation is missing, the English version is used as fallback

## Adding a New Language

To add support for a new language:

1. Create a new file named after the locale code (e.g., `itIT.lua` for Italian)
2. Copy the structure from an existing language file
3. Translate all strings
4. Add the file reference to `embeds.xml`
5. (Optional) Add localised Title and Notes to `QueueMaster.toc`

### Supported Locale Codes

- **enUS** - English (United States)
- **enGB** - English (Great Britain)
- **frFR** - French
- **deDE** - German
- **esES** - Spanish (Spain)
- **esMX** - Spanish (Mexico)
- **itIT** - Italian
- **ptBR** - Portuguese (Brazil)
- **ruRU** - Russian
- **koKR** - Korean
- **zhCN** - Chinese (Simplified)
- **zhTW** - Chinese (Traditional)

## Template for New Language File

```lua
-- ======= Locales/LOCALE.lua =======
-- LANGUAGE localisation for QueueMaster
local addonName, addon = ...
local QueueMaster = addon.QueueMaster

-- Only load if LANGUAGE locale
if GetLocale() ~= "LOCALE" then return end

local L = QueueMaster.L
if not L then return end

-- LANGUAGE translations
L["QueueMaster"] = "QueueMaster"
L["Enabled"] = "Translation here"
-- ... add all other strings
```

## Usage in Code

To use localised strings in the addon code:

```lua
local L = QueueMaster.L

-- Simple usage
print(L["Queue Ready"])

-- With concatenation
print(L["Joined:"] .. " " .. queueName)

-- With string.format
local message = string.format("%s: %s", L["Total:"], queueCount)
```

## Colour Codes in Strings

Some strings contain WoW colour codes:
- `|cffff0000` - Start red colour
- `|cff0080ff` - Start blue colour
- `|r` - Reset colour to default

Example: `"|cffff0000Queue|r|cff0080ffMaster|r"` displays as QueueMaster

## Contributing Translations

If you would like to contribute translations:

1. Fork the repository
2. Create or update the appropriate locale file
3. Test in-game with your client language
4. Submit a pull request

All contributions are appreciated!

## Translation Coverage

| Language | Status | Translator |
|----------|--------|------------|
| English (enUS/enGB) | ✅ Complete | RenZhi |
| French (frFR) | ✅ Complete | Community |
| German (deDE) | ✅ Complete | Community |
| Spanish (esES/esMX) | ✅ Complete | Community |
| Italian (itIT) | ✅ Complete | Community |
| Portuguese (ptBR) | ✅ Complete | Community |
| Russian (ruRU) | ✅ Complete | Community |
| Korean (koKR) | ✅ Complete | Community |
| Chinese Simplified (zhCN) | ✅ Complete | Community |
| Chinese Traditional (zhTW) | ✅ Complete | Community |

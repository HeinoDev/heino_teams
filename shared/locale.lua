local Config = lib.load('config')
local resource = GetCurrentResourceName()

local function load(language)
    local content = LoadResourceFile(resource, ('locales/%s.json'):format(language))
    return content and json.decode(content)
end

local strings = load(Config.Locale) or load('en')

UiLocale = strings.ui

function NotifyText(key, ...)
    return (strings.notify[key] or key):format(...)
end

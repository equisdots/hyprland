-- ═══════════════════════════════════════════════════════════════════════════
-- lib/json.lua — minimal JSON decoder for the equisdots plugin loader.
--
-- Decodes a document into Lua values: objects -> tables (string keys),
-- arrays -> tables (1-based), true/false -> booleans, null -> nil (an object
-- key with a null value is dropped). Covers the RFC 8259 value grammar,
-- including \uXXXX escapes (encoded to UTF-8; surrogate pairs handled).
--
-- Single file, no dependencies, Lua 5.4. Used by plugins.lua to read
-- settings.json and the plugin manifests only.
-- ═══════════════════════════════════════════════════════════════════════════

local json = {}

local ESCAPES = {
    ['"'] = '"', ["\\"] = "\\", ["/"] = "/",
    b = "\b", f = "\f", n = "\n", r = "\r", t = "\t",
}

local function utf8_char(cp)
    if cp < 0x80 then
        return string.char(cp)
    elseif cp < 0x800 then
        return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40)
    elseif cp < 0x10000 then
        return string.char(0xE0 + math.floor(cp / 0x1000),
                           0x80 + math.floor(cp / 0x40) % 0x40,
                           0x80 + cp % 0x40)
    end
    return string.char(0xF0 + math.floor(cp / 0x40000),
                       0x80 + math.floor(cp / 0x1000) % 0x40,
                       0x80 + math.floor(cp / 0x40) % 0x40,
                       0x80 + cp % 0x40)
end

local function skip_ws(s, i)
    local _, j = s:find("^[ \t\r\n]*", i)
    return j + 1
end

local function parse_string(s, i)
    local out = {}
    local j = i + 1
    while true do
        local c = s:sub(j, j)
        if c == "" then
            error("json: unterminated string")
        elseif c == '"' then
            return table.concat(out), j + 1
        elseif c == "\\" then
            local e = s:sub(j + 1, j + 1)
            if e == "u" then
                local hex = s:sub(j + 2, j + 5)
                local cp = tonumber(hex, 16)
                if not (hex and #hex == 4 and cp) then
                    error("json: bad \\u escape")
                end
                j = j + 6
                if cp >= 0xD800 and cp <= 0xDBFF and s:sub(j, j + 1) == "\\u" then
                    local low = tonumber(s:sub(j + 2, j + 5), 16)
                    if low and low >= 0xDC00 and low <= 0xDFFF then
                        cp = 0x10000 + (cp - 0xD800) * 0x400 + (low - 0xDC00)
                        j = j + 6
                    end
                end
                out[#out + 1] = utf8_char(cp)
            elseif ESCAPES[e] then
                out[#out + 1] = ESCAPES[e]
                j = j + 2
            else
                error("json: bad escape \\" .. e)
            end
        else
            out[#out + 1] = c
            j = j + 1
        end
    end
end

local function parse_number(s, i)
    local num = s:match("^%-?%d+%.?%d*[eE]?[+%-]?%d*", i)
    local v = num and tonumber(num)
    if v == nil then
        error("json: bad number")
    end
    return v, i + #num
end

local parse_value

local function parse_object(s, i)
    local obj = {}
    i = skip_ws(s, i + 1)
    if s:sub(i, i) == "}" then
        return obj, i + 1
    end
    while true do
        if s:sub(i, i) ~= '"' then
            error("json: expected object key")
        end
        local key
        key, i = parse_string(s, i)
        i = skip_ws(s, i)
        if s:sub(i, i) ~= ":" then
            error("json: expected ':'")
        end
        local val
        val, i = parse_value(s, i + 1)
        if val ~= nil then
            obj[key] = val
        end
        i = skip_ws(s, i)
        local d = s:sub(i, i)
        if d == "," then
            i = skip_ws(s, i + 1)
        elseif d == "}" then
            return obj, i + 1
        else
            error("json: expected ',' or '}'")
        end
    end
end

local function parse_array(s, i)
    local arr, n = {}, 0
    i = skip_ws(s, i + 1)
    if s:sub(i, i) == "]" then
        return arr, i + 1
    end
    while true do
        local val
        val, i = parse_value(s, i)
        n = n + 1
        arr[n] = val
        i = skip_ws(s, i)
        local d = s:sub(i, i)
        if d == "," then
            i = skip_ws(s, i + 1)
        elseif d == "]" then
            return arr, i + 1
        else
            error("json: expected ',' or ']'")
        end
    end
end

parse_value = function(s, i)
    i = skip_ws(s, i)
    local c = s:sub(i, i)
    if c == "{" then
        return parse_object(s, i)
    elseif c == "[" then
        return parse_array(s, i)
    elseif c == '"' then
        return parse_string(s, i)
    elseif s:sub(i, i + 3) == "true" then
        return true, i + 4
    elseif s:sub(i, i + 4) == "false" then
        return false, i + 5
    elseif s:sub(i, i + 3) == "null" then
        return nil, i + 4
    end
    return parse_number(s, i)
end

--- Decode a JSON document. Returns the value, or nil plus an error message.
function json.decode(text)
    if type(text) ~= "string" then
        return nil, "json: not a string"
    end
    local ok, val, pos = pcall(parse_value, text, 1)
    if not ok then
        return nil, tostring(val)
    end
    pos = skip_ws(text, pos)
    if pos <= #text then
        return nil, "json: trailing data"
    end
    return val
end

--- Decode a JSON file by path. Returns the value, or nil plus an error
--- message (unreadable file / invalid JSON).
function json.decode_file(path)
    local f = io.open(path, "r")
    if not f then
        return nil, "json: cannot read " .. tostring(path)
    end
    local text = f:read("*a")
    f:close()
    if not text then
        return nil, "json: cannot read " .. tostring(path)
    end
    return json.decode(text)
end

return json

local JSON     = require('json')
local timer    = require('timer')
local http     = require('http')
local https    = require('https')
local boundary = require('boundary')
local io       = require('io')
local _url     = require('_url')
require('_strings')

local __pgk        = "BOUNDARY APACHE"
local _previous    = {}
local url          = "http://127.0.0.1/server-status"
local pollInterval = 1000
local strictSSL    = true
local source, username, password


if (boundary.param ~= nil) then
  pollInterval       = boundary.param.pollInterval or pollInterval
  url                = (boundary.param.url or url)
  username           = boundary.param.username
  password           = boundary.param.password
  strictSSL          = boundary.param.strictSSL == true
  source             = (type(boundary.param.source) == 'string' and boundary.param.source:gsub('%s+', '') ~= '' and boundary.param.source) or
   io.popen("uname -n"):read('*line')
end

function berror(err)
  if err then print(string.format("%s ERROR: %s", __pgk, tostring(err))) return err end
end

--- do a http(s) request
local doreq = function(url, cb)
    local u = _url.parse(url)
    u.protocol = u.scheme
    u.path = u.path .. "?auto"
    -- reject self signed certs
    u.rejectUnauthorized = strictSSL
    if username and password then
      u.headers = {Authorization = "Basic " .. (string.base64(username..":"..password))}
    end

    local output = ""
    local onSuccess = function(res)
      res:on("error", function(err)
        cb("Error while receiving a response: " .. tostring(err), nil)
      end)
      res:on("data", function (chunk)
        output = output .. chunk
      end)
      res:on("end", function()
        if res.statusCode == 401 then return cb("Authentication required, provide user and password", nil) end
        res:destroy()
        cb(nil, output)
      end)
    end
    local req = (u.scheme == "https") and https.request(u, onSuccess) or http.request(u, onSuccess)
    req:on("error", function(err)
      cb("Error while sending a request: " .. tostring(err), nil)
    end)
    req:done()
end

function split(inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            t[i] = str
            i = i + 1
    end
    return t
end


function diff(a, b)
    if a == nil or b == nil then return 0 end
    return math.max(a - b, 0)
end

local function isempty(s)
  return s == nil or s == ''
end

function trim(s)
  if isempty(s) then return nil end
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end


function parseStatsText(body)

    local stats = {}
    for i, v in ipairs(split(body, "\n")) do
      local d = split(v, ":")
      local key = d[1]
      local val = d[2]
      stats[key] = tonumber(val) or trim(val)

    end
    return stats
end


function printStats(stats)

    local totalWorkers =  (stats['BusyWorkers'] or 0) + (stats['IdleWorkers'] or 0)
    local busyRatio = totalWorkers and stats['BusyWorkers'] / totalWorkers or 0

    local requests = diff(stats['Total Accesses'], _previous['Total Accesses'])

    -- because of the interval cut off lines, on a really slow site you will get 0's
    -- use the previous value if that happens
    stats['totalBytes'] = diff(stats['Total kBytes'], _previous['Total kBytes']) * 1024
    if requests > 0 and stats['totalBytes'] ==  0 then
      stats['totalBytes'] = _previous['totalBytes']
    end

    local bytesPerReq = requests and stats['totalBytes'] / requests or 0
    local cpuLoad = stats['CPULoad'] or 0
    if (cpuLoad > 1) then cpuLoad = cpuLoad / 100 end

    print(string.format('APACHE_REQUESTS %d %s', requests, source))
    print(string.format('APACHE_BYTES %d %s', stats['totalBytes'], source))
    print(string.format('APACHE_BYTES_PER_REQUEST %d %s', bytesPerReq, source))
    print(string.format('APACHE_CPU %d %s', cpuLoad, source))
    print(string.format('APACHE_BUSY_WORKERS %d %s', stats['BusyWorkers'], source))
    print(string.format('APACHE_IDLE_WORKERS %d %s', stats['IdleWorkers'], source))
    print(string.format('APACHE_BUSY_RATIO %d %s', busyRatio, source))

    _previous = stats

end



print("_bevent:Apache plugin up : version 1.0|t:info|tags:apache, plugin")

timer.setInterval(pollInterval, function ()

  doreq(url, function(err, body)

      if berror(err) then return end
      stats = parseStatsText(body)
      printStats(stats)

  end)

end)





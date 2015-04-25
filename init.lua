local url = require('url')
local framework = require('./modules/framework')
local Plugin = framework.Plugin
local WebRequestDataSource = framework.WebRequestDataSource
local Accumulator = framework.Accumulator

local split = framework.string.split
local auth = framework.util.auth

local params = framework.params
params.name = "Boundary Apache Plugin"
params.version = 1.1
params.tags = "apache"

local options = url.parse(params.url)
options.path = options.path .. '?auto' -- server-status?auto for text/plain output
options.auth = auth(params.username, params.password) 
--options.wait_for_end = true

local mapping = { 
  ['BusyWorkers'] = 'APACHE_BUSY_WORKERS',
  ['IdleWorkers'] = 'APACHE_IDLE_WORKERS',
  ['Total Accesses'] = 'APACHE_REQUESTS',
  ['CPULoad'] = 'APACHE_CPU',
  ['Total kBytes'] = 'APACHE_BYTES'
}
  
local data_source = WebRequestDataSource:new(options)
local acc = Accumulator:new()

local plugin = Plugin:new(params, data_source)
function plugin:onParseValues(data, _)

  -- TODO: Use map(), reduce()
  -- Capture metrics
  local result = {}
  for _, v in ipairs(split(data, "\n")) do
    local m = split(v, ":")
    local key = m[1]
    local val = m[2]
    if (key and val) then
      local metric = mapping[key] 
      if metric then
        result[metric] = tonumber(val) or -1
      end
    end
  end

  -- CPU Load calculations
  local cpu_load = result['APACHE_CPU'] or 0
  if (cpu_load > 1) then
    cpu_load = cpu_load / 100
  end
  result['APACHE_CPU'] = cpu_load

  -- Requests calculation
  local requests = acc:accumulate('APACHE_REQUESTS', result['APACHE_REQUESTS']) 
  result['APACHE_REQUESTS'] = requests

  -- Total Bytes calculation
  -- Because of the interval cut off lines, on a really slow site you will get 0's
  -- the, use the previous value if that happens
  local lastTotalBytes = acc:get('APACHE_BYTES')
  local totalBytes = acc:accumulate('APACHE_BYTES', result['APACHE_BYTES'] * 1024)
  if requests > 0 and totalBytes == 0 then
      totalBytes = lastTotalBytes
  end
  result['APACHE_BYTES'] = totalBytes

  -- Total Bytes Per Request calculation
  local bytesPerReq = (requests > 0) and (totalBytes / requests) or 0
  result['APACHE_BYTES_PER_REQUEST'] = bytesPerReq

  -- Busy Ratio calculation
  local totalWorkers =  (result['APACHE_BUSY_WORKERS'] or 0) + (result['APACHE_IDLE_WORKERS'] or 0)
  local busyRatio = totalWorkers and result['APACHE_BUSY_WORKERS'] / totalWorkers or 0
  result['APACHE_BUSY_RATIO'] = busyRatio

  return result
end
plugin:run()

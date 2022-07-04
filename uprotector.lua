if confighelp then
  return
end

local N = "uprotector"
local symbol_uprotector = "UPROTECTOR_CALLBACK"
local opts = rspamd_config:get_all_opt(N)

-- standard includes
local rspamd_http = require "rspamd_http"
local rspamd_logger = require "rspamd_logger"
local cjson = require('cjson')
-- local json = require('json')

local function http_symbol(task)

  -- define a callback
  local function request_done(err, code, body)
    if err then
      rspamd_logger.errx('http_callback error: ' .. err)
      task:insert_result('HTTP_ERROR', 1.0, err)
    else
      task:insert_result('HTTP_RESPONSE', 1.0, body)
    end
  end

  -- handle request body
  local raw_urls = task:get_urls()
  local urls = {}
  for _, url in ipairs(raw_urls) do
    table.insert(urls, tostring(url))
  end


  local test = {
	  ["force_refresh"] = true,
	  ["urls"] =  {
		"https://www.linkedin.com/in/duy-nguyen-94510b108/"
	  -- "https://google.com",
	  -- "https://bizflycloud.vn",
	  -- "https://abc.vn",
	  -- "https://abc.xyz"
		}
	}

  -- local _urls = cjson.decode(urls)
  -- rspamd_logger.infox("_urls:", _urls)
  local raw_body = {
     ["force_refresh"] = true,
     ["urls"] =  urls
  }


  local encode = cjson.encode(raw_body)

  -- initiate the request
  rspamd_http.request({
        url = 'http://10.5.69.66:30889/bulk-check',
        -- url = 'http://123.30.234.141:8912/test',
        body = encode,
        method='get',
        task = task,
        callback = request_done,
        timeout = 30,
  })
end

if opts then
  rspamd_config:register_symbol({
    name = 'URL_PROTECTOR',
    score = 1.0,
    callback = http_symbol,
  })
end

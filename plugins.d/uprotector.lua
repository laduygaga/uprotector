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

local function http_symbol(task)

  -- define a callback
  local function request_done(err, code, body)
    if err then
      rspamd_logger.errx('http_callback error: ' .. err)
    else
	  local table_body = cjson.decode(body)
      rspamd_logger.infox('message-id: ' .. task:get_message_id())
      rspamd_logger.infox('rspamd url_check response body: ' .. body)
	  if table_body['malicious'] == false then
        task:insert_result(opts.name, 0.0 , 'YES')
	  else
        task:insert_result(opts.name, 1.0, 'NO')
		malicious_urls = cjson.encode(table_body['malicious_urls'])
        task:insert_result('MALICIOUS_URLS', 0.0, malicious_urls)
	  end
    end
  end

  -- handle request body
  local raw_urls = task:get_urls()
  local urls = {}
  for _, url in ipairs(raw_urls) do
    table.insert(urls, tostring(url))
  end

  local raw_body = {
     ["force_refresh"] = true,
     ["urls"] =  urls
  }
  local encode_body = cjson.encode(raw_body)

  -- initiate the request
  rspamd_http.request({
        url = opts.url,
        body = encode_body,
        method='get',
        task = task,
        callback = request_done,
        timeout = opts.timeout,
  })
end

if opts then
  rspamd_config:register_symbol({
    name = opts.name,
    score = 1.0,
    callback = http_symbol,
	priority = 15,
  })
end

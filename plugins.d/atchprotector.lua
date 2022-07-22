if confighelp then
  return
end


local N = "atchprotector"
local symbol_atchprotector = "ATCHPROTECTOR_CALLBACK"
local opts = rspamd_config:get_all_opt(N)

-- standard includes
local rspamd_http = require "rspamd_http"
local rspamd_logger = require "rspamd_logger"
local cjson = require('cjson')

local function http_symbol(task)
-- get content of parts
  atms = {}
  for _, part in ipairs(task:get_parts()) do
    table.insert(atms, tostring(part))
  end

  -- define a callback
  local function request_done(err, code, body)
    if err then
      rspamd_logger.errx('http_callback error: ' .. err)
    else
	  local table_body = cjson.decode(body)
      rspamd_logger.infox('message-id: ' .. task:get_message_id())
      rspamd_logger.infox('rspamd url_check response body: ' .. body)
	  -- if table_body['malicious'] == true then
      --   task:insert_result(opts.name, 1.0, 'NO')
      --   if next(table_body['malicious_urls']) then
	  --     local malicious_urls = cjson.encode(table_body['malicious_urls'])
      --     task:insert_result('MALICIOUS_URLS', 0.0, malicious_urls)
	  --   end
	  -- else
      --   task:insert_result(opts.name, 0.0 , 'YES')
	  -- end
    end
  end


  -- initiate the request
  local encode_body = cjson.encode(atms)
--   headers = {
--         ['token'] = opts.token,
--         ['Cookie'] = opts.Cookie
-- 	}
  local token='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTg3MjM3NDIsImlkIjoibmFtZHoiLCJpc0FkbWluIjpmYWxzZX0.QvaHhoBtpnMkLvadlj2WINQHCx8kpe3VwjTka'
  local Cookie='JWTCookie=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTg3NDAzODEsImlkIjoibmFtZHoiLCJpc0FkbWluIjpmYWxzZX0.7-S4ubwpVRUeXtF6alDSMqPSrc89RxTaTG7SAYIhKdk'
  headers = {
        ['token'] = token,
        ['Cookie'] = Cookie
	}
  -- local encode_headers = cjson.encode(headers)
  rspamd_logger.infox('type headers: %s', type(headers))
  rspamd_logger.infox('encoded_headers: %s', headers)
  rspamd_http.request({
  	  url = 'https://api.mysaferwall.com/v1/files/',
  	  body = encode_body,
	  headers=headers,
  	  method='post',
  	  task = task,
  	  callback = request_done,
	  no_ssl_verify = true,
  	  timeout = 5,
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

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


--   headers = {
--         ['token'] = opts.token,
--         ['Cookie'] = opts.Cookie
-- 	}
local token='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTk1MzExNzQsImlkIjoibmFtZHoiLCJpc0FkbWluIjpmYWxzZX0.1BrDAodHlzw8Uio8LQu9O0qR95qSKBNPEjfVW_RPmyY'
local Cookie='JWTCookie=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTk1MzExNzQsImlkIjoibmFtZHoiLCJpc0FkbWluIjpmYWxzZX0.1BrDAodHlzw8Uio8LQu9O0qR95qSKBNPEjfVW_RPmyY'
local sha256='fa688a887062aeda5814ac80ed86881b6b45d8cc2cec50fbcfe223bcb5313aca'
local headers = {
   ['token'] = token,
   ['Cookie'] = Cookie
}


local function http_symbol(task)


  -- split string
  local function mysplit(inputstr, sep)
          if sep == nil then
                  sep = "%s"
          end
          local t={}
          for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                  table.insert(t, str)
          end
          return t
  end

  -- get mimetype of parts
  local function get_mimetype(part)
        local mysplit = mysplit(part:get_header('content-type'), ';')
		rspamd_logger.infox(mysplit[1])
  end
  for _, p in ipairs(task:get_parts()) do
    get_mimetype(p)
  end


  -- get name of parts
  local function get_name(part)
        local mysplit = mysplit(part:get_header('content-type'), '"')
		rspamd_logger.infox(mysplit[#mysplit])
  end
  for _, p in ipairs(task:get_parts()) do
    get_name(p)
  end


  -- decode base64
  local function decode_base64(bs64_encoded)
	  if bs64_encoded == nil then
		  rspamd_logger.infox("bs64_encoded is nil")
		  return nil
	  else
	    local ltn12 = require "ltn12"
	    local mime = require "mime"
	    
	    mystring = bs64_encoded
	    
	    outfile = "/tmp//test.7z"
	    
	    ltn12.pump.all(
	      ltn12.source.string(mystring),
	      ltn12.sink.chain(
	        mime.decode("base64"),
	        ltn12.sink.file(io.open(outfile,"w"))
	      )
	    )
	  end
  end

  -- get content of parts
  local function get_content_part()
    for _, part in ipairs(task:get_parts()) do
    -- rspamd_logger.infox("%s", part:get_raw_content())
    rspamd_logger.infox("%s", part:get_type())
    decode_base64(tostring(part:get_raw_content()))
    end
  end
  

  -- infected check
  local function infected_check(table_body)
	if table_body['multiav']['last_scan']['avira']['infected'] or
		table_body['multiav']['last_scan']['clamav']['infected'] or
		table_body['multiav']['last_scan']['comodo']['infected'] or
		table_body['multiav']['last_scan']['windefender']['infected'] then
		return true
	else
		return false
	end
  end

  -- upload file
  local http = require("socket.http")
  local ltn12 = require("ltn12")
  http.TIMEOUT = 5

  local function upload_file ( url, filename )
    local token='eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTkwODc5OTIsImlkIjoibmFtZHoiLCJpc0FkbWluIjpmYWxzZX0.puo34G3EdbQCQVQoBOeMptUE8vqKjnR2b-AAWk_QfDc'
    local cookie='JWTCookie=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTk1ODgxMzYsImlkIjoibmFtZHoiLCJpc0FkbWluIjpmYWxzZX0.1_datSQq0H_CbvISxKbqMhV263Cq-GCSUk4DMWdzXGA'
    local fileHandle = io.open( filename,"rb")
    if (fileHandle) then
    	local fileContent = fileHandle:read( "*a" )
    	fileHandle:close()
    	local  boundary = 'abcd'
    	local  header_b = 'Content-Disposition: form-data; name="file"; filename="' .. filename .. '"\r\nContent-Type: text/plain\r\n'
    	local  fileContent =  '--' ..boundary .. '\r\n' ..header_b ..'\r\n'.. fileContent .. '\r\n--' .. boundary ..'--\r\n'
    	local   response_body = { }
    	local   _, code = http.request {
    		url = url ,
    		method = "POST",
    		headers = {
    			["Content-Length"] =  fileContent:len(),
    			['Content-Type'] = 'multipart/form-data; boundary=' .. boundary,
    			["token"] =  token,
    			["Cookie"] = cookie
    					 },
    		source = ltn12.source.string(fileContent),
    		sink = ltn12.sink.table(response_body),
    			}
    return code, table.concat(response_body)
    else
  	return false, "File Not Found"
    end
  end

  -- local rc,content = upload_file('https://api.mysaferwall.com/v1/files/', string.format('/tmp/%s','test.txt'))
  -- rspamd_logger.infox(rc,content)


  -- define a callback
  local function request_done(err, code, body)
    if err then
      rspamd_logger.errx('http_callback error: ' .. err)
    else
	  local table_body = cjson.decode(body)
	  if code == 200 then
	    if infected_check(table_body) then
		  rspamd_logger.infox('INFECTED')
	    end
	  elseif code == 400 then
        local rc,content = upload_file('https://api.mysaferwall.com/v1/files/', string.format('/tmp/%s','test.txt'))
        rspamd_logger.infox(rc,content)
	  end
      rspamd_logger.infox('message-id: ' .. task:get_message_id())
      rspamd_logger.infox('rspamd url_check response body: ' .. body)
    end
  end

  -- get file report
  local function get_file_report(sha256) 
  rspamd_logger.infox('type headers: %s', type(headers))
  rspamd_logger.infox('encoded_headers: %s', headers)
  rspamd_http.request({
  	  url = string.format("https://api.mysaferwall.com/v1/files/%s", sha256),
  	  -- body = encode_body,
      headers=headers,
  	  method='get',
  	  task = task,
  	  callback = request_done,
      no_ssl_verify = true,
  	  timeout = 5,
  })
  end
  -- get_file_report(sha256)

end

if opts then
  rspamd_config:register_symbol({
    name = opts.name,
    score = 1.0,
    callback = http_symbol,
	priority = 15,
  })
end

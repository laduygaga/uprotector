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
	local mimetype = mysplit(part:get_header('content-type'), ';')
	return mimetype[1]
  end


  -- get name of part
  local function get_name(part)
        local name_of_part = mysplit(part:get_header('content-type'), '"')
		return name_of_part[#name_of_part]
  end


  -- get sha256 of part
  local function get_sha256(part)
     return true
  end


  -- decode base64
  local function decode_base64(bs64_encoded, to_file)
    if bs64_encoded == nil then
	  rspamd_logger.infox("bs64_encoded is nil")
	  return nil
    else
      local ltn12 = require "ltn12"
      local mime = require "mime"
      local mystring = bs64_encoded
      local outfile = string.format("/tmp/rspamd/%s", to_file)
      ltn12.pump.all(
        ltn12.source.string(mystring),
        ltn12.sink.chain(
      	mime.decode("base64"),
      	ltn12.sink.file(io.open(outfile,"w"))
        )
      )
    end
  end


  -- get raw content of part
  local function write_content(part)
	local name_of_part = get_name(part)
    decode_base64(tostring(part:get_raw_content()), name_of_part)
  end

  function table.has_key(t, key)
  	for k, _ in pairs(t) do
  		if k == key then
  			return true
  		end
  	end
  	return false
  end

  -- infected check
  local function infected_check(table_body)
    if table.has_key(table_body, "multiav") then
      if table.has_key(table_body['multiav'], "last_scan") then

  	    if table.has_key(table_body['multiav']['last_scan'], "avira") then
  	      if table_body['multiav']['last_scan']['avira'] ~= nil then
  	        if table_body['multiav']['last_scan']['avira']['infected'] then
  	        	return true
  	        end
  	      end

  	    elseif table.has_key(table_body['multiav']['last_scan'], "clamav") then
  	      if table_body['multiav']['last_scan']['clamav'] ~= nil then
  	        if table_body['multiav']['last_scan']['clamav']['infected']  then
  	          return true
  	        end
  	      end

  	    elseif table.has_key(table_body['multiav']['last_scan'], "comodo") then
  	      if table_body['multiav']['last_scan']['comodo'] ~= nil then
  	        if table_body['multiav']['last_scan']['comodo']['infected'] then
  	          return true
  	        end
  	      end

  	    elseif table.has_key(table_body['multiav']['last_scan'], "windefender") then
  	      if table_body['multiav']['last_scan']['windefender'] ~= nil then
  	        if table_body['multiav']['last_scan']['windefender']['infected'] then
  	          return true
  	        end
  	      end
	    else
	      return false
  	    end
	  else
	    return false
	  end
    else
      return false
    end
  end


  -- upload file
  local function upload_file ( url, filename )
	local token = opts.token
	local Cookie = opts.cookie
    local http = require("socket.http")
    local ltn12 = require("ltn12")
    http.TIMEOUT = 5
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
	  		["Cookie"] = Cookie
	  				 },
	  	source = ltn12.source.string(fileContent),
	  	sink = ltn12.sink.table(response_body),
	  		}
    return code, table.concat(response_body)
    else
  	  return false, "File Not Found"
    end
  end


  -- define a callback
  local function request_done(err, code, body)
    if err then
      rspamd_logger.errx('http_callback error: ' .. err)
	  return false
    else
	  local table_body = cjson.decode(body)
      rspamd_logger.infox('message-id: ' .. task:get_message_id())
      rspamd_logger.infox('rspamd url_check response body: ' .. body)
	  if code == 200 then
	    if infected_check(table_body) then
		  rspamd_logger.infox('INFECTED')
		  local infected = true
		  return infected
		  -- task:insert_result(opts.name, 1.0, 'YES')
		else
		  rspamd_logger.infox('NOT INFECTED')
		  local infected = false
		  return infected
		  -- task:insert_result(opts.name, 0.0, 'NO')
	    end
	  end
    end
  end


  -- get file report
  local function get_file_report(sha256)
	local token = opts.token
	local Cookie = opts.cookie
	local headers = {
	       ['token'] = token,
	       ['Cookie'] = Cookie
	}
    return rspamd_http.request({
    	  url = string.format(opts.url .. sha256),
          headers=headers,
    	  method='get',
    	  task = task,
    	  callback = request_done,
          no_ssl_verify = true,
    	  timeout = 5,
    })
    end


  local function sleep(n)
    os.execute("sleep " .. tonumber(n))
  end


  local infected = false
  for _, p in ipairs(task:get_parts()) do
    if get_mimetype(p) ~= 'multipart/mixed' and get_mimetype(p) ~= 'text/plain' then
  	  rspamd_logger.infox("writing content of file %s to file...", get_name(p))
  	  write_content(p)
  	  rspamd_logger.infox("uploading file %s...", get_name(p))
  	  local rc,content = upload_file(opts.url, string.format('/tmp/rspamd/%s',get_name(p)))
	  if rc == 201 then
  	    if cjson.decode(content)['sha1'] and  cjson.decode(content)['sha256'] then
	      if infected_check(cjson.decode(content)) then
		    rspamd_logger.infox('INFECTED')
		    rspamd_logger.infox('file %s is not safe', cjson.decode(content)['sha256'])
	        infected = true
	        break
	      else
	        rspamd_logger.infox('NOT INFECTED')
	      end
  	    else
	      local sha256 = cjson.decode(content)['sha256']
  	      rspamd_logger.infox("checking file: %s have sha256: %s", get_name(p), sha256)
	      sleep(2)
	      local _rc,_content = upload_file(opts.url, string.format('/tmp/rspamd/%s',get_name(p)))
		  if _rc == 201 then
	        if infected_check(cjson.decode(_content)) then
	          rspamd_logger.infox('INFECTED')
	          rspamd_logger.infox('file %s is not safe', sha256)
	          infected = true
	        else
	          rspamd_logger.infox('NOT INFECTED')
	        end
		  end
  	    end
	  end
    end
  end
  if infected == true then
	task:insert_result(opts.name, 1.0, 'NO')
  else
	task:insert_result(opts.name, 0.0, 'YES')
  end


end


if opts then
  rspamd_config:register_symbol({
    name = opts.name,
    score = 1.0,
    callback = http_symbol,
	priority = 15,
  })
end

-- 引入lua所有api
local cjson = require "cjson"
local unescape=ngx.unescape_uri
local producer = require "resty.kafka.producer"
local http = require "resty.http"
local log_json = {}
-- 定义kafka broker地址，ip需要和kafka的host.name配置一致
local broker_list = {
    { host = "es2.example.com", port = 9092 },
    { host = "es1.example.com", port = 9092 },

}

function notify(sendmail,body)
    if Alert then
        local ok,err = ngx.timer.at(0,sendmail,body)
        if not ok then
            ngx.log(ngx.ERR, "failed to create timer: ", err)
            return
        end
    end
end

function sendmail(premature,msg)
    local httpc = http.new()
    local res, err = httpc:request_uri(mailinfo['endpoint'], {
       method = "POST",
       body = cjson.encode(msg),
       headers = {
         ["Content-Type"] = "application/json",
       }
     })

    if not res then
      ngx.log(ngx.ERR,"failed to request: ",err)
      return
    end
end

function write(logfile,msg)
    local fd = io.open(logfile,"ab")
    if fd == nil then return end
    fd:write(msg)
    fd:flush()
    fd:close()
end


function json_decode( str )
    local json_value = nil
    pcall(function (str) json_value = cjson.decode(str) end, str)
    return json_value
end


log_json["uri"]=ngx.var.uri
log_json["local_ip"]="10.10.0.70"
log_json["args"]=ngx.var.args
log_json["host"]=ngx.var.host
log_json["request_body"]=tonumber(ngx.var.request_body )
log_json["remote_addr"] = ngx.var.remote_addr
log_json["remote_user"] = ngx.var.remote_user
log_json["@time_local"] =  ngx.var.time_iso8601
log_json["status"] = tostring(ngx.var.status)
log_json["body_bytes_sent"] = tonumber(ngx.var.body_bytes_sent)
log_json["http_referer"] = ngx.var.http_referer
log_json["http_user_agent"] = ngx.var.http_user_agent
log_json["http_x_forwarded_for"] = ngx.var.http_x_forwarded_for
log_json["upstream_response_time"] = tonumber( ngx.var.upstream_response_time  )
log_json["request_time"] =  tonumber(ngx.var.request_time  )

local user_name = json_decode( unescape(ngx.var.cookie_userinfo) )

if user_name  then
    log_json["username"] = user_name["username"]
end

-- 5XX的状态码发报警
if  tonumber(log_json['status'])  >= 500  then
    local m = ngx.re.match(ngx.var.host,AlertExceptDomain,"imjo")
    if m then
        return
    end
    local data =  ngx.req.get_body_data()
    local body = {}
    log_json['data'] = data   or "-"
    body["title"] = "["..log_json['host'].."]".."WEB服务端错误报警"
    body["content"] = "主机IP: "..log_json['local_ip'].."\n".."访问源IP: "..log_json['http_x_forwarded_for'].."\n".."访问时间: "..log_json['@time_local'].."\n".."状态码: "..log_json['status'].."\n".."错误URL: ".."http://"..log_json['host']..ngx.var.request_uri.."\n".."请求数据: "..log_json['data']
    body["mailto"] = mailinfo['mail_to_idc']..";"..mailinfo['mail_to_dev']


    local token = ngx.md5(ngx.var.host..ngx.var.uri)
    local logging  = ngx.shared.logging
    local req,_=logging:get(token)

    if req then
        body["content"] = "序号: "..req.."\n"..body["content"]
        if req > 5 then
            do return end;
        elseif req == 5 then
            body['content']="备注: 此URL的相关报警24小时内不再提示".."\n"..body['content']
            notify(sendmail,body)
            logging:incr(token,1)
        else
            notify(sendmail,body)
            logging:incr(token,1)
        end
    else
        logging:set(token,1,86400)
        notify(sendmail,body)
    end



--     if Alert then
--         ngx.log(ngx.ERR,Alert)
--         local ok,err = ngx.timer.at(0,sendmail,body)
--         if not ok then
--             ngx.log(ngx.ERR, "failed to create timer: ", err)
--             return
--         end
--     end

end


-- 转换json为字符串
local message = cjson.encode(log_json);
-- 定义kafka异步生产者
-- 发送日志消息,send第二个参数key,用于kafka路由控制:
-- key为nill(空)时，一段时间向同一partition写入数据
-- 指定key，按照key的hash写入到对应的partition
--write("/tmp/lua.log",message.."\n")
--ngx.log(ngx.ERR,message)

local bp = producer:new(broker_list, { producer_type = "async",request_timeout = 6000 ,flush_time = 2000,batch_num = 500 })
-- 发送日志消息,send第二个参数key,用于kafka路由控制:
-- key为nill(空)时，一段时间向同一partition写入数据
-- 指定key，按照key的hash写入到对应的partition
local ok, err = bp:send("test", nil, message)
if not ok then
    ngx.log(ngx.ERR, "kafka send err:", err)
     return
end


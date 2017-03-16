---用于将nginx日志打入kafka中
local json = require "cjson"

local producer = require "resty.kafka.producer"

local function logger(message)
    local db = "nginx_log"    
    local broker_list = {
        { host = "10.x.x.x", port = 9092 },
        { host = "10.x.x.x", port = 9093 },
        { host = "10.x.x.x", port = 9094 },
    }
    local producer_config = {
        producer_type = "async",
        request_timeout = 2000,
        required_acks = 1,
        mac_retry = 1,
        retry_backoff = 100,
        flush_time = 1000,
        batch_num = 512,
        max_buffering = 50000
    }
    local p = producer:new(broker_list,producer_config)
    local offset,err = p:send(db,nil,message)
    if not offset then
        ngx.log(ngx.ERR, "send err: ", err)
        return
    else
        -- ngx.log(ngx.OK, "send ok")
    end
end


local log_json = {}
log_json["status"] = ngx.var.status
log_json["time"] = ngx.localtime()
log_json["remote_addr"] = ngx.var.remote_addr
local x_ip=ngx.var.http_x_forwarded_for or ngx.var.remote_addr
local res,err=ngx.re.match(x_ip,"[0-9]+.[0-9]+.[0-9]+.[0-9]+")
if res then
    log_json["x_ip"] = res[0]
else
    log_json["x_ip"] = x_ip
end
log_json["method"] = ngx.var.request_method or "-"
log_json["uri"] = ngx.var.uri or "-"
log_json["query_string"] = ngx.var.query_string or "-"
log_json["body_bytes_sent"] = ngx.var.body_bytes_sent or 0
log_json["http_referer"] = ngx.var.http_referer or "-"
log_json["request_time"] = ngx.var.request_time or 0
log_json["upstream_addr"] = ngx.var.upstream_addr or "-"
log_json["upstream_status"] = ngx.var.upstream_status or "-"
log_json["upstream_response_time"] = ngx.var.upstream_response_time or 0
log_json["host"] = ngx.var.server_addr or "-"
log_json["hostname"] = ngx.var.hostname or "-"
log_json["ua"] = ngx.var.http_user_agent or "-"
log_json["active"] = ngx.var.connections_active or 0
log_json["reading"] = ngx.var.connections_reading or 0
log_json["writing"] = ngx.var.connections_writing or 0
log_json["waiting"] = ngx.var.connections_waiting or 0
local message = json.encode(log_json)
logger(message)

local ltn12 = require("resty.smtp.ltn12")
local mime = require("resty.smtp.mime")
local smtp = require("resty.smtp")
local ssl = require 'ssl'
local https = require 'ssl.https'
local socket = require("socket")
local config = require("lua.config")

local _M = {}
local function sslCreate()
    local sock = socket.tcp()
    return setmetatable({
        connect = function(_, host, port)
            ngx.log(ngx.INFO, "sock connect " .. host)
            local r, e = sock:connect(host, port)
            print("sock connect " .. host)
            if not r then return r, e end
            -- sslv3 465 与 tlsv1 port 587 一般不一样
            sock = ssl.wrap(sock, {mode='client', protocol='tlsv1'})
            --sock = ssl.wrap(sock, {mode='client', protocol='tlsv1'})
            print("sock is ", r)
            print("sock is " )
            return sock:dohandshake()
        end
    }, {
        __index = function(t,n)
            return function(_, ...)
                print("return ")
                return sock[n](sock, ...)
            end
        end
    })
end
function _M.send(self)
    mesgt = {
        from= config.from,
        headers= {
            subject = mime.ew("中文标题", nil, {}),
            ["content-transfer-encoding"] = "quoted-printable",
            ["content-type"] = "text/plain; charset='utf-8'",
        },

        body= mime.qp("中文内容，HELLO WORLD.")
    }
    local r, e = smtp.send {
        from= config.from,   -- e.g. "<user@sender.com>"
        rcpt= config.rcpt,   -- e.g. {"<user1@recipient.com>"}
        source= smtp.message(mesgt),
        server= config.server,  -- e.g. {"mail.sender.com"}
        user= config.user,      -- e.g. "user@sender.com"
        domain= config.domain,
        password= config.password,  -- password for user
        create= sslCreate,
        port = 587,
        ssl= {enable= false, verify_cert= false},
    }
    ngx.log(ngx.INFO, "send info:" .. config.from)
    if not r then
        print(e)
    end
end

return _M


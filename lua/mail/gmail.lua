-- http://stackoverflow.com/questions/11070623/lua-send-mail-with-gmail-account
-- http://stackoverflow.com/questions/29312494/sending-email-using-luasocket-smtp-and-ssl
-- Michal Kottman, 2011, public domain
local socket = require 'socket'
local smtp = require 'socket.smtp'
local ssl = require 'ssl'
local https = require 'ssl.https'
local ltn12 = require 'ltn12'

function sslCreate()
    local sock = socket.tcp()
    return setmetatable({
        connect = function(_, host, port)
            local r, e = sock:connect(host, port)
            print("sock connect")
            if not r then return r, e end
            sock = ssl.wrap(sock, {mode='client', protocol='tlsv1'})
            --sock = ssl.wrap(sock, {mode='client', protocol='tlsv1'})
            print("sock is ", r)
            print("sock is ", sock)
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

function sendMessage(subject, body)
    local msg = {
        headers = {
            from = '<zhoulpg@gmail.com>',
            to = '<zhoulpg@aliyun.com>',
            subject = subject
        },
        body = body
    }

    local ok, err = smtp.send {
        from = '<zhoulpg@gmail.com>',
        rcpt = '<zhoulpg@aliyun.com>',
        source = smtp.message(msg),
        user = "zhoulpg@gmail.com",
        password = "default",
        server = 'smtp.gmail.com',
        port = 465,
        create = sslCreate
    }
    if not ok then
        print("Mail send failed", err)
    end
end

sendMessage("nihao", "How are you!")

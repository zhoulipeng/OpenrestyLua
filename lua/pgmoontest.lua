local pgmoon = require("pgmoon")

local pg = pgmoon.new({ host = "192.168.10.231", port = 5433,
			database = "sysmanage", 
			user = "postgres",
			password = "123456",
			})
assert(pg:connect())
local res = pg:query([[select name, password from t_user where name = 'admin']])
ngx.say(res[1].password)

ngx.say(res[2].password)


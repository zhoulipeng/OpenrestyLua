############## lua 语法检查 #################################
# https://github.com/openresty/lua-nginx-module/issues/436
# http://blog.csdn.net/cjfeii/article/details/51983030
luajit -bl foo.lua > /dev/null

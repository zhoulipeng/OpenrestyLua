local mt = {}

function mt:New(o)
    o = o or {}
    -- setmetatable(o, {})
    -- self 可以继续当别人的原表
    -- setmetatable(self, {})
    self.__metatable = "can not use as a metatable"
    -- 覆盖之前的原表，不会报错
    -- https://blog.csdn.net/weixin_43112045/article/details/125490674
    -- local ret = setmetatable(o, {__metatable = "get return in function getmetatable"})
    -- 如果已经设置了__metatable属性的原表，
    -- 继续修改原表不会覆盖原来的原表，会报错 cannot change a protected metatable
    local ret = setmetatable(o, self)
    -- 成功，print返回地址 table: 0000000000e190c0
    print(ret)
    self.__index = self
    return o
end

function mt:Init()
    local ctrl1 = self:New()
    -- ctrl1.gvar = 17-- 对象2 不能读取
    self.gvar = 17 -- 对象2 可以读取
    -- mt.gvar = 17 -- 对象2 可以读取
    -- ctrl1.__metatable.gvar = 17 -- 不能直接访问 https://www.jianshu.com/p/cb945e7073a3
    -- getmetatable(ctrl1).gvar = 17
    print("gvar" .. getmetatable(ctrl1))
    print("gvar" .. ctrl1.gvar)
    local ctrl2 = self:New()
    print("gvar" .. ctrl2.gvar)
end

mt:Init()
return mt

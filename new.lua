local mt = {}

function mt:New(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function mt:Init()

    local ctrl1 = self:New()
    self.gvar = 17-- 对象2 可以读取
    -- ctrl1.gvar = 17-- 对象2 不能读取
    -- ctrl1.__metatable.gvar = 17 -- 不能直接访问 https://www.jianshu.com/p/cb945e7073a3
    print("gvar" .. ctrl1.gvar)
    local ctrl2 = self:New()
    print("gvar" .. ctrl2.gvar)

end

return mt

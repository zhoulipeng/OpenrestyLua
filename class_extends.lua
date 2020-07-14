function class(...)
    -- 返回的表类似“类”的定义
    local cls = {}
    -- 数据都存储在这里面，用作数据存储空间
    local data = {}

    -- 复制传入...的的成员。传入的...类似类定义中的成员列表。需要将父类，以及...内的成员都复制过来
    local function copyField(src, dest)
        -- 先复制父类
        if src['__super'] then
            local superMeta = getmetatable(src['__super'])
            if superMeta and superMeta['__data'] then
                for k, v in pairs(superMeta['__data']) do
                    dest[k] = v
                end
            end
        end
        -- 再复制子类，如果有重名，子类会覆盖父类
        for k, v in pairs(src) do
            if k ~= '__super' then
                dest[k] = v
            end
        end
    end
    copyField(..., data)

    -- lua 5.1之后的版本没有setfenv，引入这段代码解决setfenv问题
    if not setfenv then -- Lua 5.2
        -- based on http://lua-users.org/lists/lua-l/2010-06/msg00314.html
        -- this assumes f is a function
        local function findenv(f)
            local level = 1
            repeat
                local name, value = debug.getupvalue(f, level)
                if name == '_ENV' then
                    return level, value
                end
                level = level + 1
            until name == nil
            return nil
        end
        getfenv = function(f)
            return (select(2, findenv(f)) or _G)
        end
        setfenv = function(f, t)
            local level = findenv(f)
            if level then
                debug.setupvalue(f, level, t)
            end
            return f
        end
    end

    -- 设置cls的元表
    setmetatable(
        cls,
        {
            -- 数据存储空间
            __data = data,
            -- __newindex处理赋值时的相关逻辑，类似set
            __newindex = function(t, key, newValue)
                local oldValue = data[key]
                -- 根据旧值的类型，判断新值的类型是否相同，不相同打印提示，相同才赋值
                if oldValue then
                    if type(oldValue) == 'function' then
                        print('函数不能赋值')
                        return
                    else
                        if type(newValue) ~= type(data[key]) then
                            print('类型不匹配:', tostring(key), ' 的类型是', type(data[key]))
                            return
                        end
                    end
                end

                -- 将新值赋值
                data[key] = newValue
            end,
            -- __index处理获取值时的相关逻辑，类似get
            __index = function(t, key)
                if data[key] then
                    local value = data[key]
                    --[["
                    下面代码主要处理的是：A和B的foo函数体中都没有使用self，此时就得从全局表中获取该变量的值
                        foo = function()
                            print('from A', name, age)
                        end
                    "]]
                    if type(value) == 'function' then
                        -- 新建一个全局表
                        local newG = {}
                        setmetatable(newG, {__index = _G})
                        -- 将数据赋值到全局表中
                        for k, v in pairs(data) do
                            if type(v) ~= 'function' then
                                newG[k] = v
                            end
                        end
                        -- 设置函数的全局环境表
                        setfenv(value, newG)
                    end

                    -- 返回原始值
                    return value
                end
                return nil
            end,
            -- __call可以使class创建的对象被调用，类似构造函数的用法，调用后复制出来一个实例
            __call = function()
                local instance = {}
                setmetatable(instance, getmetatable(cls))
                return instance
            end
        }
    )

    return cls
end

--实现 class 方法
A =
    class {
    name = '',
    age = 0,
    foo = function()
        print('from A', name, age)
    end
}

B =
    class {
    __super = A,
    foo = function()
        print('from B', name, age)
    end
}

local a = A()
a.name = 'hanmeimei'
a.age = 17
a:foo()

local b = B()
b.name = 'lilei'
b.age = 18
b:foo()

a.name = 20
a.age = '20'
b.foo = 'x'

-- 要求输出

-- from A hanmeimei 17
-- from B lilei 18
-- 类型不匹配：name 的类型是 string
-- 类型不匹配：age 的类型是 number
-- 函数不能赋值

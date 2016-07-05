--[[
The MIT License (MIT)

Copyright (c) 2016 Jacob McGladdery

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

-- Cache global built-in functions
local insert   = table.insert
local ipairs   = ipairs
local next     = next
local pairs    = pairs
local print    = print
local remove   = table.remove
local sort     = table.sort
local tostring = tostring
local type     = type
local unpack   = unpack

-- Cache global built-in variables
local huge = math.huge

-- The module
local fn = {}
fn.VERSION = "0.1.0"

-- Local Functions

local function checkType(name)
    return function(value)
        return type(value) == name
    end
end

-- Arrays

function fn.reduce(array, iteratee, memo)
    local result
    local length = #array
    if length >= 1 then
        result = memo and iteratee(memo, array[1]) or array[1]
        for i = 2, length do
            result = iteratee(result, array[i])
        end
    end
    return result
end

fn.inject = fn.reduce
fn.foldl = fn.reduce

function fn.reduceRight(array, iteratee, memo)
    local result
    local length = #array
    if length >= 1 then
        result = memo and iteratee(memo, array[length]) or array[length]
        for i = length - 1, 1, -1 do
            result = iteratee(result, array[i])
        end
    end
    return result
end

fn.foldr = fn.reduceRight

-- Strings

function fn.chars(str)
    return str:gmatch(".")
end

function fn.join(separator, array)
    local result = ""
    local length = #array
    -- FIXME: Use next()
    if length >= 1 then
        result = array[1]
        for i = 2, length do
            result = result .. separator .. array[i]
        end
    end
    return result
end

-- Objects

function fn.keys(object)
    local result = {}
    for k, _ in pairs(object) do
        insert(result, k)
    end
    return result
end

function fn.values(object)
    local result = {}
    for _, v in pairs(object) do
        insert(result, v)
    end
    return result
end

function fn.pairs(object)
    local result = {}
    for k, v in pairs(object) do
        insert(result, {k, v})
    end
    return result
end

function fn.invert(object)
    local result = {}
    for k, v in pairs(object) do
        result[tostring(v)] = k
    end
    return result
end

function fn.functions(object)
    local result = {}
    for k, v in pairs(object) do
        if fn.isFunction(v) then
            insert(result, k)
        end
    end
    sort(result)
    return result
end

fn.methods = fn.functions

function fn.extend(destination, ...)
    for _, source in ipairs({...}) do
        for k, v in pairs(source) do
            destination[k] = v
        end
    end
    return destination
end

function fn.has(object, key)
    return object[key] ~= nil
end

function fn.property(key)
    return function(object)
        return object[key]
    end
end

function fn.matcher(properties)
    return function(object)
        return fn.isMatch(object, properties)
    end
end

fn.matches = fn.matcher

function fn.isMatch(object, properties)
    for k, v in pairs(properties) do
        if object[k] ~= v then
            return false
        end
    end
    return true
end

function fn.isEmpty(object)
    return next(object) == nil
end

function fn.isArray(value)
    if not fn.isTable(value) then
        return false
    end
    local i = 1
    for _ in pairs(value) do
        if nil == value[i] then
            return false
        end
        i = i + 1
    end
    return true
end

fn.isUserData = checkType("userdata")

fn.isTable = checkType("table")

fn.isFunction = checkType("function")

fn.isNumber = checkType("number")

fn.isBoolean = checkType("boolean")

function fn.isNil(object)
    return object == nil
end

function fn.isFinite(value)
    return -huge < value and value < huge
end

function fn.isInfinite(value)
    return not fn.isFinite(value)
end

function fn.isNaN(value)
    return value ~= value
end

function fn.isInteger(value)
    return value % 1 == 0
end

-- Functions

function fn.partial(func, ...)
    local args = {...}
    return function(...)
        return func(unpack(args), ...)
    end
end

function fn.after(count, func)
    count = count - 1
    return function(...)
        if count == 0 then
            return func(...)
        else
            count = count - 1
        end
    end
end

function fn.before(count, func)
    count = count - 1
    local memo
    return function(...)
        if count > 0 then
            count = count - 1
            memo = func(...)
        end
        return memo
    end
end

fn.once = fn.partial(fn.before, 2)

function fn.wrap(func, wrapper)
    return fn.partial(wrapper, func)
end

function fn.negate(predicate)
    return function(...)
        return not predicate(...)
    end
end

function fn.compose(...)
    local funcs = {...}
    return function(...)
        local result
        local length = #funcs
        if length >= 1 then
            result = {funcs[1](...)}
            for i = 2, length do
                result = {funcs[i](unpack(result))}
            end
        end
        if result then
            return unpack(result)
        end
        return result
    end
end

-- Utilities

function fn.identity(value)
    return value
end

function fn.constant(value)
    return function()
        return value
    end
end

function fn.noop()
    -- Empty
end

function fn.iteratee(value)
    if not value then
        return fn.identity
    elseif fn.isFunction(value) then
        return value
    elseif fn.isTable(value) then
        return fn.matcher(value)
    end
    return fn.property(value)
end

function fn.times(amount, iteratee)
    local result = {}
    for i = 1, amount do
        insert(result, iteratee(i))
    end
    return result
end

function fn.swap(a, b)
    return b, a
end

function fn.printTable(object, name)
    if name then
        print("Table: " .. name)
    end
    print("Key", "Value")
    print("---", "-----")
    for k, v in pairs(object) do
        print(k, v)
    end
end

function fn.printArray(array, name)
    if name then
        print("Array: " .. name)
    end
    print("Index", "Value")
    print("-----", "-----")
    for i, v in ipairs(array) do
        print(i, v)
    end
end

-- Return the module
return fn

--
-- Lua frequently used codes
-- Xintao Wang
--

-- ###################
-- #Module definition#
-- ###################
-- We use definition from a Table and use locals internally
-- mymodule.lua
require 'some_package'

local M = {} -- public interface

-- private
local x = 1
local function baz() print('test') end

local function foo() print('foo', x) end
M.foo = foo

local function bar
   foo()
   baz()
   print('bar')
end
M.bar = bar

return M

-- Example usage:
local MM = require 'mymodule'
MM.bar()
local json = require "cjson"
-- local pb = require("luapbintf")
local io = require "io"
local crc32 = require "crc32"
local tool = require "tool"
local lfstool = require "lfstool"
local lfs = require "lfs"

local pb = require "pb"

-- 协议号映射表
local name2code = {}
local code2name = {}

--分析proto文件，计算映射表
local function analysis_file(path)
	local file = io.open(path, "r")
	local package = ""

	for line in file:lines() do
		local s, c = string.gsub(line, "^%s*package%s*([^%s]+)%s*[;%s].*$", "%1")
		if c > 0 then
			package = s
		end
		-- local s, c = string.gsub(line, "^%s*message%s*([^%s]+)%s*[{%s].*$", "%1")
		local s, c = string.gsub(line, "^%s*message%s*([^%s]+)%s*$", "%1")
		if c > 0 then
			local name = package.."."..s
			local code = crc32.hash(name)
			print(string.format("analysis proto: %s->%d(%x)", name, code, code))
			name2code[name] = code
			code2name[code] = name
		end
	end
	file:close()
end

--导入proto文件，并analysis_file
local path = lfs.currentdir()  --eg /root/zServer/test
pbpath = string.sub(path, 1, -5).."proto"  --eg /root/zServer/proto

-- pb.add_proto_path("/")

lfstool.attrdir(pbpath, function(file)
	local proto_file = string.match(file, "(.+%.proto)")
	if proto_file then
		analysis_file(proto_file)
	end
	local pb_file = string.match(file, "(.+%.pb)")
	if pb_file then
		assert(pb.loadfile(pb_file))
	end
end)

-- local login = {
-- 	account = "tanghailong",
-- 	password = "123456",
-- 	skdid = 1
-- }

-- local echo = {
-- 	str = "232313"
-- }


for name, basename, type in pb.types() do
  print(name, basename, type)
end
-- 序列化成二进制数据
-- local data = assert(pb.encode("login.login", login))

-- 从二进制数据解析出实际消息
-- local msg = assert(pb.decode("login.login", data))


--打印二进制string，用于调试
local function bin2hex(s)
	s=string.gsub(s,"(.)",function (x) return string.format("%02X ",string.byte(x)) end)
	return s
end

local M = {}

--cmd:login.Login
--checkcode:1234
--msg:{account="1",password="1234"}
function M.pack(cmd, check, msg)
	--格式说明
	--> >:big endian
	-->i2:前面两位为长度
	-->i4:int32 checkcode
	-->I4:uint32 cmd_code

	--code
	local code = name2code[cmd]
	if not code then
		print(string.format("protopack_pb fail, cmd:%s", cmd or "nil"))
		return
	end
	print("pack code:"..code)
	--check
	check = check or 0
	--pbstr
	local pbstr = pb.encode(cmd, msg)
	local pblen = string.len(pbstr)
	--len
	local len = 4+4+pblen
	--组成发送字符串
	local f = string.format("> i2 i4 I4 c%d", pblen)
	local str = string.pack(f, len, check, code, pbstr)
	print("f:", f)
	print("str:", str)
	--??
	print("send pbstr:"..bin2hex(pbstr))
	print("send:"..bin2hex(str))
	print(string.format("send:cmd(%s) check(%d) msg->%s", cmd, check, tool.dump(msg)))
	return str
end

function M.unpack(str)
	local pblen = string.len(str)-4-4
	local f = string.format("> i4 I4 c%d", pblen)
	local check, code, pbstr = string.unpack(f, str)
	local cmd = code2name[code]
	local msg = pb.decode(cmd, pbstr)
	print("recv:"..bin2hex(str))
	print("recv pbstr:"..bin2hex(pbstr))
	print(string.format("recv:cmd(%s) check(%d) msg->%s", cmd, check, tool.dump(msg)))
	return cmd, check, msg
end




return M



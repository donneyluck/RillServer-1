local skynet = require "skynet"
require "skynet.manager"

local cluster = require "skynet.cluster"
local runconf = require(skynet.getenv("runconfig"))
local servconf = runconf.service
local nodename = skynet.getenv("nodename")

local function start_host()
	for k,v in pairs(servconf.host_common) do
				if nodename == v.node and v.name == "web" then
						skynet.uniqueservice(v.name, "host", v.port)
				end
	end
end

local function start_console()
	for i,v in pairs(servconf.debug_console) do
		if nodename == v.node then
			skynet.uniqueservice("debug_console", v.port)
			ERROR("start debug_console in port: " .. v.port.."...")
		end
	end
end

local function start_setup()
	local p = skynet.newservice("setup", "setup", 0)
end

local function start_gateway()
	for i, v in pairs(servconf.gateway) do
		local name = string.format("gateway%d", i)
		if nodename == v.node then
			local p = skynet.newservice("gateway", "gateway", i)

			local c = servconf.gateway_common
			local g = servconf.gateway[i]
			skynet.name(name, p)
			skynet.call(p, "lua", "open", {
				port = g.port,
				maxclient = c.maxclient,
				nodelay = c.nodelay,
				name = name,
			})
		else
			local proxy = cluster.proxy(v.node, name)
			skynet.name(name, proxy)
		end
	end
end

local function start_agentpool()
	--开启agentpool服务
	for i,v in pairs(servconf.agentpool) do
		local name = string.format("agentpool%d", i)
		if nodename == v.node then
			local c = servconf.agentpool_common
			local agentname = runconf.prototype .. "agent"

			local p = skynet.newservice("agentpool", "agentpool", i)
			skynet.name(name, p)

			skynet.call(p, "lua", "init_pool", {
				agentname = agentname,
				maxnum = c.maxnum,
				recyremove = c.recyremove,
				brokecachelen = c.brokecachelen,
			})
		else
			local proxy = cluster.proxy(v.node, name)
			skynet.name(name, proxy)
		end
	end
end

local function start_login()
	for i,v in pairs(servconf.login) do
		local name = string.format("login%d", i)
		if nodename == v.node then
			local p = skynet.newservice("login", "login", i)
		else
			local proxy = cluster.proxy(v.node, name)
			skynet.name(name, proxy)
		end
	end
end

local function start_dbproxy()
	for i,v in pairs(servconf.dbproxy) do
		local name = string.format("dbproxy%d", i)
		if nodename == v.node then
			local p = skynet.newservice("dbproxy", "dbproxy", i)
		else
			local proxy = cluster.proxy(v.node, name)
			skynet.name(name, proxy)
		end
	end
end

local function start_center()
	for i,v in pairs(servconf.center) do
		local name = string.format("center%d", i)
		if nodename == v.node then
			local p = skynet.newservice("center", "center", i)
		else
			local proxy = cluster.proxy(v.node, name)
			skynet.name(name, proxy)
		end
	end
end

local function start_global()
	for i,v in pairs(servconf.global) do
		local name = string.format("global%d", i)
		if nodename == v.node then
			local p = skynet.newservice("global", "global", i)
		else
			local proxy = cluster.proxy(v.node, name)
			skynet.name(name, proxy)
		end
	end
end


skynet.start(function()

	INFO("Server start version: " .. runconf.version)
	--集群信息
	--cluster.reload(runconf.cluster)
	--cluster.open(nodename)
	--开启各个服务
	start_console()
	start_host()
	start_agentpool()
	start_setup()
	start_global()
	start_login()
	start_dbproxy()
	start_center()
	start_gateway()
	skynet.exit()
end)

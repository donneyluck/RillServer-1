-- local w = require "wsclient"
local w = require "tcpclient"
local uid
local STATUS = {idel=1, game=2}
local status = 0
seed = arg[1] or os.time()

--1-登陆 -> 请求创建房间
function login_loginresult(msg)
	print("onRecv.login_loginresult")
	status = STATUS.idel
	uid = msg.uid
	w.send("create_room_req", {game = "move"})
	--w.send("example.echo", {str = "echo "..uid})
end

function create_room_resp(msg)
	w.send("enter_room_req", {})
end


--2-进入房间
function life_enter_room(msg)
	status = STATUS.game
	w.send("life.update_map", {})
	w.send("life.list", {""})
	print("onRecv.life_enter_room")
end

--3-收到地图信息
function life_update_map(msg)
	print("onRecv.update_map")
end

--4-收到同步协议
function life_sync(msg)
	print("onRecv.life_list")
	--移动
	local rmsg = {}
	if math.random(1,100) < 5 then
		x = math.random(-1,1)
		rmsg.x = x
	end
	if math.random(1,100) < 5 then
		rmsg.action = 1
	end
	
	if rmsg.x or rmsg.action then
		w.send("life.input", rmsg)
	end

	--离开
	if math.random(1, 30*60) < 2 then
		w.send("life.leave", {})
		status = STATUS.idel
	end
	--意外退出
	if math.random(1, 30*60*20) < 2 then
		w.stop = true
	end
end

--2-进入房间
function example_echo(msg)
	w.send("example.echo", {str = "echo "..uid})
	print("onRecv.example_echo")
end


function onTimer()
	-- if status == STATUS.idel then
	-- 	if math.random(1, 10*300) < 2 then
	-- 		w.send("life.enter_room", {})
	-- 	end
	-- end
end

function onRecv(cmd, msg)
	funname = string.gsub(cmd, "%.", "_");
	if _G[funname] then
		_G[funname](msg)
	end
end

math.randomseed(seed)

w.sleep(math.random(10,20))
w.connect("127.0.0.1", 11798, onRecv, onTimer)
local account = "robot"..math.random(1,99999999)
w.login(account, "123456")
w.start()

os.execute("sleep 1")

-- local RoomMove = require "room_move.room_move_logic.room_init" --class('RoomMove')

local RoomMove = class("RoomMove")
local libcenter = require "libcenter"
local tablex = require "pl.tablex"

function RoomMove:initialize()
    DEBUG("=============RoomMove Init=================")
    self._players = {}
end

function RoomMove:is_player_num_overload()
    return tablex.size(self._players) >= 4
end

function RoomMove:enter(data)
    local uid = data.uid
    local player = {
        uid = uid,
        agent = data.agent,
        node = data.node,
    }

    self._players[uid] = player
    self:broadcast({cmd="movegame.add", uid = uid,}, uid)
    return SYSTEM_ERROR.success
end

function RoomMove:leave(uid)
    self._players[uid] = nil
    self:broadcast({cmd="movegame.leave", uid=uid,}, uid)

    return SYSTEM_ERROR.success
end

function RoomMove:broadcast(msg, filter_uid)
    for k, v in pairs(self._players) do
        if filter_uid and filter_uid ~= k then
            libcenter.send2client(k, msg)
        end
    end
end

return RoomMove

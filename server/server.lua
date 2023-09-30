local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------------------------------
-- version checker
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'

    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/Rexshack-RedM/rsg-example/main/version.txt', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')

        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end

        --versionCheckPrint('success', ('Current Version: %s'):format(currentVersion))
        --versionCheckPrint('success', ('Latest Version: %s'):format(text))
        
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end

-----------------------------------------------------------------------

-- check your bills recived
RSGCore.Functions.CreateCallback('rsg-billing:server:checkbills', function(source, cb, citizenid)
    MySQL.query('SELECT * FROM player_bills WHERE citizenid = ?', {citizenid}, function(result)
        if result[1] ~= nil then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

RSGCore.Functions.CreateCallback('rsg-billing:server:checkSentBills', function(source, cb, citizenid)
    MySQL.query('SELECT * FROM player_bills WHERE sendercitizenid = ?', {citizenid}, function(result)
        if result[1] ~= nil then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

-- pay bills
RegisterNetEvent('rsg-billing:server:paybills', function(data)
    if Config.Debug == true then
        print(data.sender)
        print(data.amount)
        print(data.billid)
        print(data.society)
        print(data.citizenid)
        print(data.sendercitizenid)
    end
    local src = source
    local PayingPlayer = RSGCore.Functions.GetPlayer(src)
    local PaidPlayer = RSGCore.Functions.GetPlayerByCitizenId(data.sendercitizenid) or RSGCore.Functions.GetOfflinePlayerByCitizenId(data.sendercitizenid)
    if data.society == 'personal' then
        if PayingPlayer.PlayerData.money.cash >= data.amount then
            PayingPlayer.Functions.RemoveMoney("cash", data.amount, "pay-bill")
            PaidPlayer.Functions.AddMoney("cash", data.amount, "player-pay-bill")
            exports.oxmysql:execute('DELETE FROM player_bills WHERE id = ?', {data.billid})
            TriggerClientEvent('RSGCore:Notify', src, 'Bill has been paid for '..data.amount..'$', 'success')
        else
            TriggerClientEvent('RSGCore:Notify', src, 'You not have enough money', 'error')
        end
    else
        if PayingPlayer.PlayerData.money.cash >= data.amount then
            PayingPlayer.Functions.RemoveMoney("cash", data.amount, "pay-bill")
            exports['rsg-bossmenu']:AddMoney(data.society, data.amount)
            exports.oxmysql:execute('DELETE FROM player_bills WHERE id = ?', {data.billid})
            TriggerClientEvent('RSGCore:Notify', src, 'Bill has been paid for '..data.amount..'$', 'success')
        else
            TriggerClientEvent('RSGCore:Notify', src, 'You not have enough money', 'error')
        end
    end
end)

-- cancel bill
RegisterNetEvent('rsg-billing:server:cancelbill', function(billid)
    if Config.Debug == true then
        print(billid)
    end
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    exports.oxmysql:execute('DELETE FROM player_bills WHERE id = ?', {billid})
    TriggerClientEvent('RSGCore:Notify', src, 'Bill with ID: '..billid..' has been deleted', 'success')
end)

-- send bill as society
RegisterNetEvent('rsg-billing:server:sendSocietyBill', function(playerid, amount, society)
    local src = source
    local SendPlayer = RSGCore.Functions.GetPlayer(src)
    local SendName = (SendPlayer.PlayerData.charinfo.firstname..' '..SendPlayer.PlayerData.charinfo.lastname)
    local Player = RSGCore.Functions.GetPlayer(tonumber(playerid))
    if Player then
        exports.oxmysql:insert('INSERT INTO player_bills (citizenid, amount, society, sender, sendercitizenid) VALUES (?, ?, ?, ?, ?)',
        {
            Player.PlayerData.citizenid,
            amount,
            society,
            SendName, 
            SendPlayer.PlayerData.citizenid
        })
        TriggerClientEvent('RSGCore:Notify', source, 'Bill Sent', 'success')
        TriggerClientEvent('RSGCore:Notify', playerid, 'You received a $'..amount..' bill', 'success')
    else
        TriggerClientEvent('RSGCore:Notify', source, 'Did not find player', 'error')
    end
end)

-- send bill as a player
RegisterNetEvent('rsg-billing:server:sendPlayerBill', function(playerid, amount)
    local src = source
    local SendPlayer = RSGCore.Functions.GetPlayer(src)
    local SendName = (SendPlayer.PlayerData.charinfo.firstname..' '..SendPlayer.PlayerData.charinfo.lastname)
    local Player = RSGCore.Functions.GetPlayer(tonumber(playerid))
    if Player then
        exports.oxmysql:insert('INSERT INTO player_bills (citizenid, amount, society, sender, sendercitizenid) VALUES (?, ?, ?, ?, ?)',
        {
            Player.PlayerData.citizenid,
            amount,
            'personal',
            SendName,
            SendPlayer.PlayerData.citizenid
        })
        TriggerClientEvent('RSGCore:Notify', source, 'Bill Sent', 'success')
        TriggerClientEvent('RSGCore:Notify', playerid, 'You received a $'..amount..' bill', 'success')
    else
        TriggerClientEvent('RSGCore:Notify', source, 'Did not find player', 'error')
    end
end)

-- command to open the billing menu rather than radial
RSGCore.Commands.Add("billing", "Opens the Billing Menu", {}, false, function(source)
    local src = source
    TriggerClientEvent('rsg-billing:client:billingMenu', src)
end)

-- start version check
--------------------------------------------------------------------------------------------------
CheckVersion()

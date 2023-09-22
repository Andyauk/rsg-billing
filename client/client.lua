local RSGCore = exports['rsg-core']:GetCoreObject()
local jobcheck = false

-- main billing menu
RegisterNetEvent('rsg-billing:client:billingMenu', function()
    lib.registerContext({
        id = 'bill_mainmenu',
        title = 'Billing Menu',
        options = {
            {
                title = 'Send Bill',
                description = '',
                icon = 'fas fa-dollar-sign',
                event = 'rsg-billing:client:billplayer',
                arrow = true
            },
            {
                title = 'View Your Bills',
                description = '',
                icon = 'fa-solid fa-eye',
                event = 'rsg-billing:client:checkbills',
                arrow = true
            },
            {
                title = 'Cancel Sent Bill',
                description = '',
                icon = 'fa-solid fa-xmark',
                iconColor = 'red',
                event = 'rsg-billing:client:deletebills',
                arrow = true
            },
        }
    })
    lib.showContext("bill_mainmenu")
end)

-- bill player
RegisterNetEvent('rsg-billing:client:billplayer', function()
    local input = lib.inputDialog('Bill Player', {
        { 
            label = 'PlayerID',
            type = 'number',
            required = true,
            icon = 'fa-solid fa-id-card'
        },
        { 
            label = 'Bill Amount',
            type = 'number',
            required = true,
            icon = 'fa-solid fa-dollar-sign'
        },
        { 
            label = 'Bill Type',
            type = 'select',
                options = {
                    { value = "player", label = "Bill as Player" },
                    { value = "society", label = "Bill as Society" },
                },
            required = true,
            icon = 'fa-solid fa-file-invoice'
        },
    })
    if not input then return end
    
    if input[3] == 'society' then
        local playerjob = RSGCore.Functions.GetPlayerData().job.name
        jobcheck = false
        for _, name in pairs(Config.VerifySociety) do
            if name == playerjob then
                jobcheck = true
            end
        end
        if jobcheck == true then
            TriggerServerEvent('rsg-billing:server:sendSocietyBill', input[1], input[2], playerjob)    
        else
            RSGCore.Functions.Notify('you are not part of a society!', 'error')
        end
    end
    if input[3] == 'player' then
        TriggerServerEvent('rsg-billing:server:sendPlayerBill', input[1], input[2])
    end
end)

-- check bills
RegisterNetEvent('rsg-billing:client:checkbills', function()
    local citizenid = RSGCore.Functions.GetPlayerData().citizenid
    RSGCore.Functions.TriggerCallback('rsg-billing:server:checkbills', function(result)
        if result == nil then
            lib.registerContext({
                id = 'no_bills',
                title = 'Check Bills',
                menu = 'bill_mainmenu',
                onBack = function() end,
                options = {
                    {
                        title = 'No Bills',
                        description = 'you have no bills to pay!',
                        icon = 'fa-solid fa-box',
                        disabled = true,
                        arrow = false
                    }
                }
            })
            lib.showContext("no_bills")
        else
            local options = {}
            for _, v in pairs(result) do
                options[#options + 1] = {
                    title = 'Bill-ID: '..result[1].id,
                    description = 'Bill from '..result[1].sender..' for the amount of $'..result[1].amount,
                    icon = 'fa-solid fa-user-check',
                    serverEvent = 'rsg-billing:server:paybills',
                    args = {
                            sender = result[1].sender, 
                            amount = result[1].amount, 
                            billid = result[1].id, 
                            society = result[1].society,
                            citizenid = result[1].citizenid,
                            sendercitizenid = result[1].sendercitizenid
                    },
                    arrow = true
                }
                lib.registerContext({
                    id = 'checkbills_menu',
                    title = 'Check Bills',
                    menu = 'bill_mainmenu',
                    onBack = function() end,
                    position = 'top-right',
                    options = options
                })
                lib.showContext('checkbills_menu')
            end
        end
    end, citizenid)
end)

-- cancel bill
RegisterNetEvent('rsg-billing:client:deletebills', function()
    local citizenid = RSGCore.Functions.GetPlayerData().citizenid
    RSGCore.Functions.TriggerCallback('rsg-billing:server:checkSentBills', function(result)
        if result == nil then
            lib.registerContext({
                id = 'no_sentbills',
                title = 'Sent Bills',
                menu = 'bill_mainmenu',
                onBack = function() end,
                options = {
                    {
                        title = 'No Sent Bills',
                        description = 'you have not sent any bills!',
                        icon = 'fa-solid fa-box',
                        disabled = true,
                        arrow = false
                    }
                }
            })
            lib.showContext("no_sentbills")
        else
            local options = {}
            for _, v in pairs(result) do
                options[#options + 1] = {
                    title = 'Bill ID: ' .. result[1].id,
                    description = 'Amount $' .. result[1].amount .. ' | to : ' .. result[1].citizenid,
                    icon = 'fas fa-dollar-sign',
                    event = 'rsg-billing:client:cancelbill',
                    args = {
                        billid = result[1].id,
                    },
                    arrow = true
                }
                lib.registerContext({
                    id = 'sentbills_menu',
                    title = 'Sent Bills',
                    menu = 'bill_mainmenu',
                    onBack = function() end,
                    position = 'top-right',
                    options = options
                })
                lib.showContext('sentbills_menu')
            end
        end
    end, citizenid)
end)

-- confirm cancel bill
RegisterNetEvent('rsg-billing:client:cancelbill', function(data)
    local input = lib.inputDialog('Cancel Bill', {
        { 
            label = 'Bill ID : '..data.billid,
            type = 'select',
                options = {
                    { value = "yes", label = "Yes" },
                    { value = "no", label = "No" },
                },
            required = true,
        },
    })
    if not input then return end
    
    if input[1] == 'yes' then
        TriggerServerEvent('rsg-billing:server:cancelbill', tonumber(data.billid))
        RSGCore.Functions.Notify('Bill Canceled!', 'primary')
    else
        RSGCore.Functions.Notify('Action Canceled!', 'primary')
        return
    end
end)

local Translations = {
error = {
    var = 'texto aqui',
},
success = {
    var = 'texto aqui',
},
primary = {
    var = 'texto aqui',
},
menu = {
    var = 'texto aqui',
},
commands = {
    var = 'texto aqui',
},
progressbar = {
    var = 'texto aqui',
},

}

if GetConvar('rsg_locale', 'en') == 'pt-br' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end

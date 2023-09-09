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

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})

-- Lang:t('error.horse_too_far')

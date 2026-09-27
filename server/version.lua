local config = require 'config'

if not config.versionCheckEnabled then return end

lib.versionCheck('Sleepless-Development/sleepless_routing')

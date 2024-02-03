#### Features

- **Vehicle Tracking**: Track nearby vehicles from the equipped emergency vehicle.
- **Real-time Updates**: Marked vehicle location updates are displayed in real-time on the map.
- **Blip Expiry Timer**: Blips expire after a set duration to avoid clutter on the map.
- **Cooldown System**: Prevents spamming of the tracking feature by imposing a cooldown period.
- **Customizable Blip Settings**: Configure the appearance of blips on the map.
- **Configurable Options**: Customize various aspects such as cooldown duration, blip settings, command usage, and keybind.
- **Dart Attach Success Sound**: Provides audible feedback upon successful attachment of the dart.





# INSTALLATION


Install these items to your ox_inventory/data/items.lua
Then install images to ox_inventory/web/images    







    ['dart_device'] = {
        label = 'D.A.R.T',
        weight = 1000,  -- Adjust weight as needed
        stack = false,  -- Assuming one dart_device cannot be stacked
        close = true,   -- Close inventory after use
        consume = 1,    -- Consumes 1 dart_device per use
        description = 'DART_Device',
        client = {
            export = 'Stoic-Dart.FireDart'  -- Calls the 'FireDart' export from client.lua
        }
    },
    ['angle_grinder'] = {
        label = 'Angle Grinder',
        weight = 1000,  -- Adjust weight as needed
        stack = false,  -- Assuming one dart_device cannot be stacked
        close = true,   -- Close inventory after use
        consume = 1,    -- Consumes 1 dart_device per use
        description = 'Used to saw off all sorts of stuff including a GPS tracker!',
        client = {
            usetime = 900,
            export = 'Stoic-Dart.PlayerRemoveDart'  -- Calls the 'FireDart' export from client.lua
            
        }
    }
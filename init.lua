local function mailbox_formspec(pos)
  local spos = pos.x .. "," .. pos.y .. "," .. pos.z

  return
    "formspec_version[4]" ..
    "size[12,11]" ..

    "list[nodemeta:" .. spos .. ";main;1,0.4;8,4;]" ..

    "button[3,4.6;4,0.8;getitems;Get Items]" ..

    "list[current_player;main;1,5.8;8,4;]" ..
    "listring[]"
end

-- Wait until ALL mods have registered their nodes.
core.register_on_mods_loaded(function()

  if not core.registered_nodes["homedecor:inbox"] then
    core.log("error", "[jc_mailbox] homedecor:inbox not found!")
    return
  end

  core.override_item("homedecor:inbox", {

    on_rightclick = function(pos, node, clicker, itemstack)

      local meta = core.get_meta(pos)
      local owner = meta:get_string("owner")
      local player = clicker:get_player_name()

      if player == owner or
        (core.check_player_privs(player, "protection_bypass")
        and clicker:get_player_control().aux1) then

        core.show_formspec(
          player,
          "jc_mailbox:" .. core.pos_to_string(pos),
          mailbox_formspec(pos)
        )

      else
        -- Original deposit-only formspec
        local spos = pos.x .. "," .. pos.y .. "," .. pos.z

        core.show_formspec(
          player,
          "jc_mailbox_insert",
          "size[8,9]" ..
          "list[nodemeta:"..spos..";drop;3.5,2;1,1;]" ..
          "list[current_player;main;0,5;8,4;]" ..
          "listring[]"
        )
      end

      return itemstack
    end,
  })

  core.log("action", "[jc_mailbox] Mailbox overridden successfully.")
end)

core.register_on_player_receive_fields(function(player, formname, fields)

  if not fields.getitems then
    return
  end

  local posstr = formname:match("^jc_mailbox:(.*)$")
  if not posstr then
    return
  end

  local pos = core.string_to_pos(posstr)
  if not pos then
    return
  end

  local meta = core.get_meta(pos)

  if meta:get_string("owner") ~= player:get_player_name() then
    return
  end

  local mail = meta:get_inventory()
  local inv = player:get_inventory()

  for i = 1, mail:get_size("main") do
    local stack = mail:get_stack("main", i)

    if not stack:is_empty() then
      local leftover = inv:add_item("main", stack)
      mail:set_stack("main", i, leftover)
    end
  end

  core.sound_play("default_item_smoke", {
    to_player = player:get_player_name(),
    gain = 0.6,
  })

  core.show_formspec(
    player:get_player_name(),
    formname,
    mailbox_formspec(pos)
  )
end)
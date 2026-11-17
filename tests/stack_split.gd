extends Node
var failures := 0
var checks := 0
var service: InventoryService
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok: failures += 1; push_error(message)
func _ready() -> void: run.call_deferred()
func data(index: int, amount: int, chest: bool = false) -> Dictionary:
 return {"index":index,"amount":amount,"storage":chest,"revision":service.view_revision,"service_id":service.get_instance_id()}
func click(point: Vector2, button: MouseButton, down: bool, shift: bool = false) -> void:
 var event := InputEventMouseButton.new()
 event.position = point
 event.global_position = point
 event.button_index = button
 event.pressed = down
 event.shift_pressed = shift
 get_viewport().push_input(event)
func split_click(button: InventorySlotButton, target: InventorySlotButton, half: bool) -> void:
 var source := button.get_global_rect().get_center()
 click(source,MOUSE_BUTTON_RIGHT,true,half)
 click(source,MOUSE_BUTTON_RIGHT,false,half)
 await get_tree().process_frame
 check(not service.hud.cursor_data.is_empty(),"Right click starts a cursor stack")
 var point := target.get_global_rect().get_center()
 var motion := InputEventMouseMotion.new()
 motion.position = point
 motion.global_position = point
 get_viewport().push_input(motion)
 await get_tree().process_frame
 click(point,MOUSE_BUTTON_LEFT,true)
 click(point,MOUSE_BUTTON_LEFT,false)
 await get_tree().process_frame
func run() -> void:
 get_tree().create_timer(25).timeout.connect(func() -> void: get_tree().quit(1))
 GameWindow.set_preference("fullscreen",false)
 GameWindow.set_preference("pause_unfocused",false)
 get_window().size = Vector2i(1280,720)
 VoyageState.reset()
 var main := preload("res://scenes/main.tscn").instantiate()
 add_child(main)
 service = main.get_node("Ship/InventorySystem")
 await get_tree().process_frame
 await get_tree().process_frame
 service.inventory.clear()
 service.storage.clear()
 service.player.position = service.storage_position
 service.hud.storage_open = true
 service.inventory.try_add(&"gold_coin",21)
 # Use a catalogued stackable item if the currency id differs.
 if service.inventory.slots[0].is_empty(): service.inventory.try_add(&"wood",21)
 await get_tree().process_frame
 await get_tree().process_frame
 var item: StringName = service.inventory.slots[0].id
 await split_click(service.hud.buttons[0],service.hud.buttons[1],false)
 check(service.inventory.slots[0].get("quantity",0)==20 and service.inventory.slots[1].get("quantity",0)==1,"Right click moves exactly one")
 await split_click(service.hud.buttons[0],service.hud.chest_buttons[0],true)
 check(service.inventory.slots[0].get("quantity",0)==10 and service.storage.slots[0].get("quantity",0)==10,"Shift right click moves half into chest")
 await split_click(service.hud.chest_buttons[0],service.hud.buttons[1],false)
 check(service.storage.slots[0].get("quantity",0)==9 and service.inventory.slots[1].get("quantity",0)==2,"One item can be taken from a chest")
 await split_click(service.hud.chest_buttons[0],service.hud.buttons[2],true)
 check(service.storage.slots[0].get("quantity",0)==4 and service.inventory.slots[2].get("quantity",0)==5,"Odd half rounds up without losing items")
 var before := service.inventory.capture()
 var source_point: Vector2 = service.hud.buttons[0].get_global_rect().get_center()
 click(source_point,MOUSE_BUTTON_RIGHT,true)
 click(source_point,MOUSE_BUTTON_RIGHT,false)
 await get_tree().process_frame
 var padding: Vector2 = service.hud.chest_panel.get_global_rect().position+Vector2(8,8)
 var cursor := InputEventMouseMotion.new()
 cursor.position=padding
 cursor.global_position=padding
 get_viewport().push_input(cursor)
 await get_tree().process_frame
 click(padding,MOUSE_BUTTON_LEFT,true)
 click(padding,MOUSE_BUTTON_LEFT,false)
 await get_tree().process_frame
 check(service.inventory.capture()==before and service.hud.cursor_data.is_empty(),"Cancelled cursor split leaves source untouched")
 service.request_drag(data(0,999),3)
 check(service.inventory.capture()==before,"Oversized quantity rejected")
 service.request_drag(data(0,0),3)
 service.request_drag(data(0,-2),3)
 check(service.inventory.capture()==before,"Zero and negative quantities rejected")
 var stale := data(0,1)
 service.publish()
 service.request_drag(stale,3)
 check(service.inventory.capture()==before,"Stale split rejected")
 service.inventory.try_add(&"fishing_rod",1)
 before=service.inventory.capture()
 service.request_drag(data(0,1),3)
 check(service.inventory.capture()==before,"Partial stack never swaps with a different item")
 service.request_drag(data(0,1))
 check(service.drops.size()==1 and int(service.drops.values()[0].quantity)==1,"One item can be dropped on ground")
 var serial := service.pickup_serial
 service.player.position += Vector2(70,0)
 service.server_pickups()
 service.player.position -= Vector2(70,0)
 service.server_pickups()
 check(service.pickup_serial==serial+1 and service.drops.is_empty(),"Successful pickup advances sound event once")
 service.server_pickups()
 check(service.pickup_serial==serial+1,"Standing on pickup does not repeat sound")
 check(GameWindow._sounds.has("pickup"),"Pickup sound is loaded")
 var total := service.inventory.get_quantity(item)
 for entry in service.storage.slots:
  if entry.get("id",&"")==item: total+=entry.quantity
 check(total==21,"All operations conserve original stack")
 service.inventory.clear()
 service.inventory.try_add(&"fishing_rod")
 service.inventory.try_add(&"spyglass")
 await get_tree().process_frame
 for index in [0,1]:
  var point: Vector2 = service.hud.buttons[index].get_global_rect().get_center()
  click(point,MOUSE_BUTTON_RIGHT,true)
  click(point,MOUSE_BUTTON_RIGHT,false)
  check(service.hud.cursor_data.is_empty(),"Non-stackable tool cannot be right-click split")
 var rod_point: Vector2 = service.hud.buttons[0].get_global_rect().get_center()
 click(rod_point,MOUSE_BUTTON_LEFT,true)
 click(rod_point,MOUSE_BUTTON_LEFT,false)
 await get_tree().process_frame
 check(not service.hud.cursor_data.is_empty(),"Left-click carries stack after mouse release")
 check(service.hud.buttons[0].entry.is_empty() and service.inventory.slots[0].id==&"fishing_rod","Cursor hides reserved source without removing authoritative item")
 check(service.hud.cursor_layer.layer > service.hud.layer,"Cursor renders above grill and chest UI")
 var empty_point: Vector2 = service.hud.buttons[2].get_global_rect().get_center()
 click(empty_point,MOUSE_BUTTON_LEFT,true)
 click(empty_point,MOUSE_BUTTON_LEFT,false)
 await get_tree().process_frame
 check(service.inventory.slots[0].is_empty() and service.inventory.slots[2].id==&"fishing_rod","Second left-click places item into chosen slot")
 click(empty_point,MOUSE_BUTTON_LEFT,true)
 click(empty_point,MOUSE_BUTTON_LEFT,false)
 service.hud.close()
 check(service.hud.cursor_data.is_empty() and service.inventory.slots[2].id==&"fishing_rod","Closing chest returns held item to source")
 service.hud.storage_open=true
 click(empty_point,MOUSE_BUTTON_LEFT,true)
 click(empty_point,MOUSE_BUTTON_LEFT,false)
 service.player.position+=Vector2(100,0)
 await get_tree().process_frame
 await get_tree().process_frame
 check(service.hud.cursor_data.is_empty() and service.inventory.slots[2].id==&"fishing_rod","Leaving chest range cancels cursor safely")
 if "--capture" in OS.get_cmdline_user_args():
  var grill: Node2D = main.get_node("Ship/Cooking")
  service.player.position = grill.position
  service.hud.grill_open = true
  service.inventory.clear()
  service.inventory.try_add(&"fish_cod",4)
  await get_tree().process_frame
  service.hud.pick_cursor(0,false)
  service.hud.message_time=0
  var overlay_mouse :=  InputEventMouseMotion.new()
  overlay_mouse.position = service.hud.grill_panel.get_global_rect().get_center()
  overlay_mouse.global_position = overlay_mouse.position
  get_viewport().push_input(overlay_mouse)
  await get_tree().process_frame
  await RenderingServer.frame_post_draw
  check(service.hud.cursor_layer.visible and service.hud.cursor_icon.get_global_rect().intersects(service.hud.grill_panel.get_global_rect()),"Cursor overlaps grill on the higher canvas")
  get_viewport().get_texture().get_image().save_png("res://.godot/cursor-over-grill.png")
  click(overlay_mouse.position,MOUSE_BUTTON_LEFT,true)
  click(overlay_mouse.position,MOUSE_BUTTON_LEFT,false)
  check(grill.fish.size()==1 and service.inventory.get_quantity(&"fish_cod")==3,"Cursor click places a fish on the grill")
 print("STACK SPLIT: %d checks, %d failures" % [checks,failures])
 get_tree().quit(1 if failures else 0)

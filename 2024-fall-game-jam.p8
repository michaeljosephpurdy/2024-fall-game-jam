pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
function _init()
 music(0)
 state='intro'
 game_state='deal_hand'
 dt=1/60
 -- setup mouse
 poke(0x5f2d, 1)
 mouse={
  x=0,
  y=0,
  draw=function(self)
   palt()
   if stat(34)==1 then
    spr(2,self.x,self.y)
   else
    spr(1,self.x,self.y)
   end
  end,
 }
 player_one=new_player(1)
 player_two=new_player(2)
 skip_button={
  x=3,
  y=106,
  w=16,
  h=8,
  draw=function(self)
   spr(9,self.x,self.y+sin(time())+.1,2,1)
  end,
 }
 cards={
 }
 mobs={
 }
 msgs={}
 player_one_hand={}
 player_two_hand={}
 player_one_card_lanes={
  new_card_lane('top',1),
  new_card_lane('mid',1),
  new_card_lane('bot',1),
 }
 player_two_card_lanes={
  new_card_lane('top',2),
  new_card_lane('mid',2),
  new_card_lane('bot',2),
 }
 card_lanes={}
 foreach(player_one_card_lanes,function(l)
  add(card_lanes,l)
 end)
 foreach(player_two_card_lanes,function(l)
  add(card_lanes,l)
 end)
 player_one_mobs={}
 player_two_mobs={}
 deck=new_deck(1)
 smokes={}
 timed_functions={}
end
function new_smoke (x,y)
 return {
  x=x,
  y=y,
  dx=rnd(2)-1,
  dy=rnd(1)-1,
 }
end

function new_card_lane (t,p)
 local lane={
  head=nil,
  body=nil,
  legs=nil,
  mob=nil,
  player=p,
  id=rnd()*1000,
 }
 lane.x=2
 lane.w=45
 lane.h=20
 lane.t=t
 lane[t]=true
 if lane.player==2 then
  lane.x+=77
 end
 lane.head_x=lane.x
 lane.body_x=lane.x+16
 lane.legs_x=lane.x+32
 if t=='top' then
  lane.y=10
 elseif t=='mid' then
  lane.y=40
 elseif t=='bot' then
  lane.y=70
 end
 return lane
end
function new_mob (p,t,head,body,legs)
 local x,y=48,0
 if p==2 then
  x+=20
 end
 if t=='top' then
  y=10
 elseif t=='mid' then
  y=40
 elseif t=='bot' then
  y=60
 end
 local hp=head.hp+body.hp+legs.hp
 local atk=head.atk+body.atk+legs.atk
 local name=head.desc..body.desc..legs.desc
 return {
  name=name,
  x=x,
  y=y,
  w=16,
  h=16,
  head=head.s,
  body=body.s,
  legs=legs.s,
  player=p,
  t=t,
  [t]=t,
  hp=hp,
  max_hp=hp,
  atk=atk,
  hit=false,
  id=rnd()*1000,
  get_stats=function(self)
   return self.name.. ' '..self.atk..'! ♥'..self.hp
  end,
  draw=function(self)
   local ox,oy=0,0
   if self.hit then
    ox=rnd(2)-1
    oy=rnd(2)-1
   end
   palt()
   palt(0,false)
   palt(14,true)
   local flip_h=p==2
   spr(self.head,self.x+ox,self.y+oy,2,2,flip_h)
   spr(self.body,self.x+ox,self.y+15+oy,2,2,flip_h)
   spr(self.legs,self.x+ox,self.y+30+oy,2,2,flip_h)
  end,
  draw_stats=function(self)
   ocprint('♥'..self.hp,
           self.x+4,
           self.y+16,
           8,0)
   ocprint(self.atk..'!',
           self.x+6,
           self.y+22,
           12,1)
  end,
 }
end
function new_card (x,y,t,p)
 local card={
  p=p,
  player=p,
  x=x,
  y=y,
  w=2*8,
  h=3*8,
  placed=false,
  turned_over=true,
  get_stats=function(self)
   return self.name..' '..self.atk..'! ♥'..self.hp
  end,
  draw=function(self) 
   palt()
   if self.turned_over then
    spr(14,self.x,self.y,2,3)
    return
   end
   -- draw background
   if self.bg then
    color(self.bg)
   elseif self.p==2 then
    color(0)
   elseif self.head then
    color(13)
   elseif self.body then
    color(3)
   elseif self.legs then
    color(2)
   end
   -- draw border
   rectfill(self.x+1,self.y+1,self.x+14,self.y+22)
   spr(5,self.x,self.y,2,1)
   line(self.x,self.y+2,self.x,self.y+20,7)
   line(self.x+15,self.y+2,self.x+15,self.y+20,7)
   -- draw bottom
   spr(3,self.x,self.y+16,2,1)
   print(self.hp,self.x+12,self.y+17,1)
   print(self.atk,self.x+5,self.y+17,1)
   -- draw sprite
   palt(0,false)
   palt(14,true)
   spr(self.s,self.x,self.y,2,2)
  end,
 }
 if t=='random' then
  t=rnd(card_types)
 end
 for k,v in pairs(card_data[t]) do
  card[k]=v
 end
 return card
end
function new_deck (p)
 return {
  x=2,
  y=97,
  w=2*8,
  h=3*8,
  draw=function(self)
   spr(14,self.x-2,self.y+2,2,3)
   spr(14,self.x-1,self.y+1,2,3)
   spr(14,self.x,self.y,2,3)
  end,
  on_click=function(self)
  end,
 }
end
function new_player (num)
 return {
  num=num,
  hp=100,
  hit=false,
 }
end
function collide (e1,e2)
 return e1.x+(e1.w or 0)>e2.x and
        e1.x<e2.x+(e2.w or 0) and
        e1.y+(e1.h or 0)>e2.y and
        e1.y<e2.y+(e2.h or 0)
end

function _update60 ()
 game_state_msg=nil
 hover_card=nil
 hover_lane=nil
 hover_mob=nil
 show_skip_button=false
 mouse.x=stat(32)
 mouse.y=stat(33)
 foreach(msgs,update)
 foreach(timed_functions,function(tfn)
  tfn.ttl-=dt
  if tfn.ttl<0 then
   tfn.fn()
   del(timed_functions,tfn)
  end
 end)
 foreach(card_lanes,function(l)
  if collide(mouse,l) then
   hover_lane=l
  end
 end)
 if state=='you_win' then
  if not game_over then
   game_over=true
   add(msgs,new_moving_msg(
    'you win!',900,
    64,20,
    0,-.02,
    8,2))
  end
 elseif state=='you_lose' then
  if not game_over then
   game_over=true
   add(msgs,new_moving_msg(
    'you lose!',900,
    64,20,
    0,-.02,
    8,2))
   add(msgs,new_moving_msg(
    'try again',900,
    64,30,
    0,-.02,
    8,2))
  end
 elseif state=='intro' then
  if not co_intro then
   co_intro=cocreate(function()
    add(msgs,new_moving_msg(
     'create monsters by',3,
     64,20,
     0,-.02,
     8,2))
    add(msgs,new_moving_msg(
     'fusing their parts.',4,
     64,30,
     0,-.02,
     8,2))
    while #msgs>0 do
     yield()
    end
    add(msgs,new_moving_msg(
     '',1,
     64,80,
     0,-.02,
     8,2))
    while #msgs>0 do
     yield()
    end
    add(msgs,new_moving_msg(
     'your creations will',4,
     64,60,
     0,-.02,
     8,2))
    add(msgs,new_moving_msg(
     'protect you and',5,
     64,70,
     0,-.02,
     8,2))
    add(msgs,new_moving_msg(
     'smite your enemies.',6,
     64,80,
     0,-.02,
     8,2))
    while #msgs>0 do
     yield()
    end
    add(msgs,new_moving_msg(
     '',1,
     64,80,
     0,-.02,
     8,2))
    while #msgs>0 do
     yield()
    end
    add(msgs,new_moving_msg(
     'these creations are',4,
     64,60,
     0,-.02,
     8,2))
    add(msgs,new_moving_msg(
     'imperfect, and will',5,
     64,70,
     0,-.02,
     8,2))
    add(msgs,new_moving_msg(
     'slowly pass on.',6,
     64,80,
     0,-.02,
     8,2))
    while #msgs>0 do
     yield()
    end
    add(msgs,new_moving_msg(
     '',1,
     64,80,
     0,-.02,
     8,2))
    while #msgs>0 do
     yield()
    end
    add(msgs,new_moving_msg(
     'you must draw one.',4,
     64,20,
     0,0,
     8,2))
    add(msgs,new_moving_msg(
     'you may play one.',5,
     64,60,
     0,0,
     8,2))
    add(msgs,new_moving_msg(
     'you must discard one.',6,
     64,100,
     0,0,
     8,2))
    while #msgs>0 do
     yield()
    end
    add(msgs,new_moving_msg(
     'click to start',60,
     64,120,
     0,0,
     8,2))
    while stat(34)==0 do
     yield()
    end
   end)
  end
  coresume(co_intro)
  if costatus(co_intro)=='dead' then
   msgs={}
   state='game'
   game_state='deal_hand'
  end
 elseif state=='game' then
  foreach(mobs,function(m)
   if collide(mouse,m) then
    hover_mob=m
   end
  end)
  foreach(cards,function(c)
   if c.target_x then
    c.x=lerp(c.x,c.target_x,1/20)
   end
   if c.target_y then
    c.y=lerp(c.y,c.target_y,1/20)
   end
   if collide(mouse,c) then
    hover_card=c
    return
   end
  end)
  if game_state=='deal_hand' then
   if #player_one_hand==0 then
    for i=0,3 do
     local card=new_card(deck.x,deck.y,'random',1)
     card.target_x=deck.x+i*20+20
     card.target_y=deck.y
     card.start_x=card.target_x
     card.start_y=card.y
     add(player_one_hand,card)
     add(cards,card)
    end
   end
   local done=true
   foreach(player_one_hand,function(c)
    c.done=ceil(c.x)==c.target_x
    c.turned_over=not c.done
    done=c.done and done
   end)
   if done then
    game_state='draw_one'
    sfx(18)
   end
  elseif game_state=='draw_one' then
   game_state_msg='draw a card'
   if drew_card then
    drew_card.done=ceil(drew_card.x)==drew_card.target_x
    drew_card.turned_over=not drew_card.done
    if drew_card.done then
     game_state='play_one'
     drew_card=nil
    end
   else
    local c=new_card(deck.x,deck.y,'random',1)
    add(player_one_hand,c)
    c.target_x=deck.x+(#player_one_hand-1)*20+20
    c.start_x=c.target_x
    c.start_y=c.y
    add(cards,c)
    drew_card=c
   end
  elseif game_state=='play_one' then
   show_skip_button=true
   game_state_msg='play a card'
   if click_on(skip_button) then
    play_cpu_card()
    sfx(20)
    game_state='discard_one'
    found_monsters=false
   end
   -- mouse down
   if stat(34)==1 then
    -- are we holding a card?
    if held_card then
     held_card.x=mid(0,mouse.x-held_offset_x,110)
     held_card.y=mid(0,mouse.y-held_offset_y,100)
    else
     -- are we picking up a card?
     foreach(player_one_hand,function(c)
      if not c.placed and
         c==hover_card then
       held_card=c
       held_card.start_x=c.x
       held_card.start_y=c.y
       held_offset_x=mouse.x-c.x
       held_offset_y=mouse.y-c.y
       foreach(card_lanes,function(l)
        l.valid=false
        if l.player==2 then
         return
        end
        if c.head and not l.head then
         l.valid=true
        elseif c.body and not l.body then
         l.valid=true
        elseif c.legs and not l.legs then
         l.valid=true
        end
       end)
      end
     end)
    end
   else
    local lane=nil
    foreach(card_lanes,function(l)
     if not l.valid then
      return
     end
     if not collide(mouse,l) then
      return
     end
     held_card.placed=true
     del(player_one_hand,held_card)
     if held_card.head then
      held_card.target_x=l.head_x
      l.head=held_card
     elseif held_card.body then
      held_card.target_x=l.body_x
      l.body=held_card
     elseif held_card.legs then
      held_card.target_x=l.legs_x
      l.legs=held_card
     end
     held_card.target_y=l.y
     held_card=nil
     play_cpu_card()
     -- is lane complete?
     game_state='discard_one'
     sfx(19)
     found_monsters=false
    end)
    if held_card and not lane then
     held_card.target_x=held_card.start_x
     held_card.target_y=held_card.start_y
    end
    held_card=nil
    valid_spots=nil
    foreach(card_lanes,function(l)
     l.valid=false
    end)
    spr(1,mouse.x,mouse.y)
   end
  elseif game_state=='discard_one' then
    -- make all monsters
    if not found_monsters then
     found_monsters=true
     foreach(card_lanes,function(l)
      if not (l.head and
              l.body and
              l.legs) then
       return
      end
      local mob=new_mob(
       l.player,
       l.t,
       l.head,
       l.body,
       l.legs
      )
      sfx(21)
      add(msgs,
       new_moving_msg('its alive!',1.5,
       l.legs_x,l.y+2,
       0,-0.2,
       11,2))
      add(msgs,
       new_moving_msg(mob.name,1.5,
       l.legs_x,l.y+10,
       0,-0.2,
       11,2))
      -- delete the cards
      del(cards,l.head)
      del(cards,l.body)
      del(cards,l.legs)
      -- reset the lane
      l.head=nil
      l.body=nil
      l.legs=nil
      -- find any existing mob
      local existing=nil
      foreach(mobs,function(m)
       if mob.player==m.player and
          mob.t==m.t then
        existing=m
       end
      end)
      -- remove the mob
      if existing then
       del(mobs,existing)
      end
      -- add new mob
      add(mobs,mob)
      distribute_mobs()
    end)
   end
   game_state_msg='discard a card'
   if hover_card and
      hover_card.p==1 and
      not hover_card.placed and
      click_on(hover_card) then
    del(cards,hover_card)
    del(player_one_hand,hover_card)
    game_state='deal_damage'
    sfx(22)
   end  
   for i,c in pairs(player_one_hand) do
     c.target_x=deck.x+i*20
   end
  elseif game_state=='deal_damage' then
   if not routines_built then
    routines_built=true
    top_co=setup_mob_atk('top')
    mid_co=setup_mob_atk('mid')
    bot_co=setup_mob_atk('bot')
   else
    coresume(top_co)
    if costatus(top_co)=='dead' then
     coresume(mid_co)
    end
    if costatus(mid_co)=='dead' then
     coresume(bot_co)
    end
    if costatus(bot_co)=='dead' then
     if #player_one_hand==0 then
      game_state='deal_hand'
     else
      game_state='draw_one'
     end
     if player_one.hp<=0 then
      state='you_lose'
     elseif player_two.hp<=0 then
      state='you_win'
     end
     routines_built=false
    end
   end
  end
 end
end

function _draw ()
 if state=='intro' or
    state=='you_lose' or
    state=='you_win' then
  cls(0)
  mouse:draw()
  foreach(msgs,draw)
 elseif state=='game' then
  cls(1)
  foreach(card_lanes,function(lane)
   if lane==hover_lane and
      lane.player==1 then
    color(7)
   elseif lane.valid then
    color(10)
   else
    color(0)
   end
   if not lane.mob then
    rect(lane.x,lane.y,lane.x+lane.w,lane.y+lane.h)
    if lane.player==2 then
     rectfill(lane.x,lane.y,lane.x+lane.w,lane.y+lane.h)
    end
   end
  end)
  deck:draw()
  if show_skip_button then
   skip_button:draw()
  end
  -- draw mobs in-order
  foreach(filter(mobs,'top'),draw)
  foreach(filter(mobs,'mid'),draw)
  foreach(filter(mobs,'bot'),draw)
  foreach(cards,draw)
  if held_card then
   rectfill(held_card.x+1,
            held_card.y+1,
            held_card.x+2*8,
            held_card.y+3*8+1,0)
   held_card:draw()
  end
  palt()
  mouse:draw()
  if game_state_msg then
   ocprint(game_state_msg,64,
          sin(time())+.1+3,10,2)
  end
  if hover_card and
     not hover_card.turned_over and
     not held_card then
   ocprint(hover_card:get_stats(),64,122,10,0)
  elseif hover_mob then
     hover_mob:draw()
   ocprint(hover_mob:get_stats(),64,122,10,0)
   mouse:draw()
  end
  if held_card then
   cprint(held_card.name,64,120,10)
  end
  local p1_hp_x,p1_hp_y=17,2
  local p2_hp_x,p2_hp_y=107,2
  if player_one.hit then
   p1_hp_x-=rnd(2)-1
   p1_hp_y-=rnd(2)-1
  end
  if player_two.hit then
   p2_hp_x-=rnd(2)-1
   p2_hp_y-=rnd(2)-1
  end
  ocprint('p1 ♥'..player_one.hp,p1_hp_x,p1_hp_y,8,0)
  ocprint('p2 ♥'..player_two.hp,p2_hp_x,p2_hp_y,8,0)
  foreach(msgs,draw)
 end
end

function cprint(msg,x,y,c)
 print(msg,x-#msg*2,y,c)
end
function ocprint(msg,x,y,c,oc)
 cprint(msg,x-1,y-1,oc)
 cprint(msg,x-1,y,oc)
 cprint(msg,x-1,y+1,oc)
 cprint(msg,x,  y-1,oc)
 cprint(msg,x,  y,oc)
 cprint(msg,x,  y+1,oc)
 cprint(msg,x+1,y-1,oc)
 cprint(msg,x+1,y,oc)
 cprint(msg,x+1,y+1,oc)
 cprint(msg,x,y,c)
end

function lerp(a,b,t)
 return a+(b-a)*t
end

function click_on(obj)
 return stat(34)==1 and
        collide(mouse,obj)
end

function filter (tbl,arg)
 local fn=arg
 if type(arg)=='string' then
  fn=function(i)
   return i[arg]
  end
 end
 local res={}
 foreach(tbl,function(item)
  if fn(item) then
   add(res,item)
  end
 end)
 return res
end

function play_cpu_card ()
 local c=new_card(0,-30,'random',2)
 c.turned_over=false
 local found=nil
 local checked={}
 while true do
  -- get a random lane
  local l=rnd(player_two_card_lanes)
  -- if the card can fit in lane
  -- use it
  if c.head and not l.head then
   found=l
   break
  end
  if c.body and not l.body then
   found=l
   break
  end
  if c.legs and not l.legs then
   found=l
   break
  end
  -- if we can't fit in that lane
  -- then don't check this lane
  -- again
  add(checked,l)
  -- if we've checked all lanes
  -- then stop looking
  if #checked==#player_two_card_lanes then
   break
  end
 end
 if found then
  c.target_y=found.y
  if c.head then
   c.target_x=found.head_x
   found.head=c
  elseif c.body then
   c.target_x=found.body_x
   found.body=c
  elseif c.legs then
   c.target_x=found.legs_x
   found.legs=c
  end
  add(cards,c)
 end
end

function contains(tbl,key)
 for k,_ in pairs(tbl) do
  if key==k then
   return true
  end
 end
 return false
end

function setup_mob_atk (lane_type)
 local empty_coroutine=cocreate(function()
 end)
 local p1m=nil
 local p2m=nil
 local delay=1
 foreach(player_one_mobs,function(m)
  if m.t==lane_type then
   p1m=m
  end
 end)
 foreach(player_two_mobs,function(m)
  if m.t==lane_type then
   p2m=m
  end
 end)
 if not p1m and not p2m then
  return empty_coroutine
 end
 local delay_func=function()
  if p1m then
   p1m.hp-=flr(p1m.hp*.2)
   entity_hit(p1m)
   if p1m.hp<=0 then
    del(mobs,p1m)
    p1m=nil
   end
  end
  if p2m then
   p2m.hp-=flr(p2m.hp*.2)
   entity_hit(p2m)
   if p2m.hp<=0 then
    del(mobs,p2m)
    p2m=nil
   end
  end
  if not p1m or not p2m then
   distribute_mobs()
  end
  while delay>0 do
   delay-=dt
   yield()
  end
 end
 local pre_func=function()
 end
 local atk_func=function()
 end
 local post_func=function()
 end
 if p1m and p2m then
  printh('both atk')
  local p1_start_x=p1m.x
  local p1_target_x=p1m.x+10
  local p2_start_x=p2m.x
  local p2_target_x=p2m.x-10
  pre_func=function()
   while ceil(p1m.x)~=p1_target_x and
         flr(p2m.x)~=p2_target_x do
    p1m.x=lerp(p1m.x,p1_target_x,1)
    p2m.x=lerp(p2m.x,p2_target_x,1)
    yield()
   end
  end
  atk_func=function()
   p2m.hp-=p1m.atk
   p1m.hp-=p2m.atk
   entity_hit(p1m)
   entity_hit(p2m)
   sfx(16)
  end
  post_func=function()
   while flr(p1m.x)~=p1_start_x and
         ceil(p2m.x)~=p2_start_x do
    p1m.x=lerp(p1m.x,p1_start_x,1/7)
    p2m.x=lerp(p2m.x,p2_start_x,1/7)
    yield()
   end
   p1m.x=p1_start_x
   p2m.x=p2_start_x
   if p1m.hp<=0 then
    del(mobs,p1m)
    distribute_mobs()
   end
   if p2m.hp<=0 then
    del(mobs,p2m)
    distribute_mobs()
   end
  end
 elseif p1m then
  printh('p1 atk')
  local start_x=p1m.x
  local target_x=p1m.x+20
  pre_func=function()
   while ceil(p1m.x)~=target_x do
    p1m.x=lerp(p1m.x,target_x,1)
    yield()
   end
  end
  atk_func=function()
   player_two.hp-=p1m.atk
   entity_hit(player_two)
   sfx(17)
  end
  post_func=function()
   while flr(p1m.x)~=start_x do
    p1m.x=lerp(p1m.x,start_x,1/7)
    yield()
   end
   p1m.x=start_x
  end
 elseif p2m then
  printh('p2 atk')
  local start_x=p2m.x
  local target_x=p2m.x-20
  pre_func=function()
   while flr(p2m.x)~=target_x do
    p2m.x=lerp(p2m.x,target_x,1)
    yield()
   end
  end
  atk_func=function()
   player_one.hp-=p2m.atk
   entity_hit(player_one)
   sfx(17)
  end
  post_func=function()
   while ceil(p2m.x)~=start_x do
    p2m.x=lerp(p2m.x,start_x,1/7)
    yield()
   end
   p2m.x=start_x
  end
 end
 return cocreate(function()
  delay_func()
  pre_func()
  atk_func()
  post_func()
 end)
end

function draw(e)
 e:draw()
end
function update(e)
 e:update()
end

function distribute_mobs ()
 player_one_mobs={}
 player_two_mobs={}
 foreach(mobs,function(m)
  if m.player==1 then
   add(player_one_mobs,m)
  else
   add(player_two_mobs,m)
  end
 end)
end

function new_moving_msg (msg,ttl,x,y,dx,dy,c,oc)
 return {
  msg=msg,
  ttl=ttl,
  x=x,
  y=y,
  dx=dx,
  dy=dy,
  c=c,
  oc=oc,
  update=function(self)
   self.x+=self.dx
   self.y+=self.dy
   self.ttl-=dt
   if self.ttl<0 then
    del(msgs,self)
   end
  end,
  draw=function(self)
   ocprint(self.msg,self.x,self.y,self.c,self.oc)
  end,
 }
end

function entity_hit (e)
 e.hit=true
 add(timed_functions,{
  ttl=1,
  fn=function()
   e.hit=false
  end,
 })
end
-->8
card_data={
 frank_head={
  name='frankenstein head',
  s=70,
  hp=4,
  atk=1,
  head=true,
  desc='fran',
 },
 frank_body={
  name='frankenstein body',
  s=72,
  hp=5,
  atk=2,
  body=true,
  desc='ken',
 },
 frank_legs={
  name='frankenstein legs',
  s=74,
  hp=4,
  atk=3,
  legs=true,
  desc='stien',
 },
 drac_head={
  name='dracula head',
  s=64,
  hp=3,
  atk=3,
  head=true,
  desc='dra',
 },
 drac_body={
  name='dracula body',
  s=66,
  hp=3,
  atk=2,
  body=true,
  desc='cu',
 },
 drac_legs={
  name='dracula legs',
  s=68,
  hp=2,
  atk=0,
  legs=true,
  desc='la',
 },
 wolf_head={
 	name='werewolf head',
 	s=76,
 	hp=3,
 	atk=2,
 	head=true,
 	desc='wer',
	},
	wolf_body={
 	name='werewolf body',
 	s=78,
 	hp=4,
 	atk=3,
 	body=true,
 	desc='ew',
	},
	wolf_legs={
 	name='werewolf legs',
 	s=110,
 	hp=3,
 	atk=2,
 	legs=true,
 	desc='olf',
	},
	pump_head={
 	name='pumpkin head',
 	s=96,
 	hp=2,
 	atk=3,
 	head=true,
 	desc='pu',
	},
		pump_body={
 	name='pumpkin body',
 	s=98,
 	hp=1,
 	atk=4,
 	body=true,
 	desc='mpk',
	},
		pump_legs={
 	name='pumpkin legs',
 	s=100,
 	hp=1,
 	atk=3,
 	legs=true,
 	desc='in',
	}
}
card_types={}
for k,v in pairs(card_data) do
 add(card_types,k)
end
__gfx__
00000000010000000000000077777777777777770077777777777700700000000000000700666666666666600000000000000000000000000066666666666600
000000001c10000001000000706000000808000707000000000000707000000000000007065575777777777600000000000000000000000006ddddd121dddd60
007007001cc100001c10000070600000088800077000000000000007700000000000000765777577757555760000000000000000000000006dd1111121111dd6
000770001ccc10001cc1000070600000088800077000000000000007700000000000000765557575777575760000000000000000000000006d111111211111d6
000770001cccc1001ccc100075550000088800077000000000000007700000000000000767757557757555760000000000000000000000006d111112118111d6
007007001cc111001cccc10070400000008000077000000000000007700000000000000765577575757577760000000000000000000000006d111112118111d6
00000000511555001cc1110007000000000000707000000000000007700000000000000767777777777577600000000000000000000000006d111121111811d6
00000000055000000110000000777777777777007000000000000007700000000000000706666666666666000000000000000000000000006d111211111811d6
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee00000000000000006d112111111811d6
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000eeeeeeeeeeeeeeeeeeeeee00000000000000006d112111118111d6
eeeeee33333eeeeeeeeeeeebbeeeeeeeeeeee111111eeeeeeeeeeeeeeeeeeeeeeeeee0000eeeeeeeeeeeee00000eeeee00000000000000006d111211181111d6
eeeee333333eeeeeeeeeee7777eeeeeeeeeee111111eeeeeeeeeee00000eeeeeeeeeee0000eeeeeeeeeee000000eeeee00000000000000006d111118811111d6
eeee3333333eeeeeeeeeebbb77eeeeeeeeeee111111eeeeeeeeee000000eeeeeeeeeee0000eeeeeeeeeee000000eeeee00000000000000006d111181111111d6
eeee3333bbbeeeeeeeeebbbb77eeeeeeeeeee111111eeeeeeeeee000000eeeeeeeeee00000eeeeeeeeeee000000eeeee00000000000000006d111811112111d6
eeee33b3b7beeeeeeeeebbb777eeeeeeeeeee111111eeeeeeeee0007777eeeeeeeeee00000eeeeeeeeeee000000eeeee00000000000000006d118111111211d6
eeee33bbb1beeeeeeeeebbb777eeeeeeeeeee111c11eeeeeeeee7007767eeeeeeeee000000eeeeeeeeeeee00000eeeee00000000000000006d118111111211d6
eeee3bbbb1beeeeeeeeebbb777eeeeeeeeeee111c11eeeeeeeee7077707eeeeeeeee000100eeeeeeeeeeee0000eeeeee00000000000000006d118111112111d6
eeeeebbbbbbeeeeeeeeebbb777eeeeeeeeeee111c11eeeeeeeee7777707eeeeeeeee000100eeeeeeeeeeee0000eeeeee00000000000000006d111811121111d6
eee55bbbbbbeeeeeeeeebbb777eeeeeeeeeee111c11eeeeeeeee0777777eeeeeeeee000100eeeeeeeeeeee00000eeeee00000000000000006d111811211111d6
eee5566bb44eeeeeeeeeebb7bbbeeeeeeeeee111c11eeeeeeeee0077777eeeeeeeeee00100eeeeeeeeeeee00000eeeee00000000000000006d111111211111d6
eee5566bbbbeeeeeeeeeebbbbbbeeeeeeeeee111c11eeeeeeeeee077788eeeeeeeeee00700eeeeeeeeeeee00000eeeee00000000000000006d111112111111d6
eee55bbbbbbeeeeeeeeeeebbbbbeeeeeeeeee11441444eeeeeeeee77777eeeeeeeeee70700eeeeeeeeeeee00000eeeee00000000000000006dd1111211111dd6
eeeeeeebbbeeeeeeeeeeee7777eeeeeeeeeee444441444eeeeeeeee77eeeeeeeeeeee77700eeeeeeeeeeee011011eeee000000000000000006dddd121ddddd60
eeeeeeebbbeeeeeeeeeeee7777eeeeeeeeeee444441444eeeeeeeee77eeeeeeeeeeeee000eeeeeeeeeeeee111011eeee00000000000000000066666666666600
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee2222772222eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee01111ee11110eeeee4eeeeeeee4eeeeeeeeeeeeeeeeeee
eeeeee0000eeeeeeeeeee000000eeeeeeee0000000000eeeee000000000000eeeee111155511eeeeee01111ee11110eeee404e4444e404eeeeee44444444eeee
eeee00000000eeeeeee0090000900eeeeee0000000000eeee000000b0b00000ee11111155511111eee01111ee11110eeee404444444404eeee444444444444ee
eee0000000000eeeee00a077770a00eeeee0000000000eeee00b0b0bbb0b000e1111115555111111ee01111ee11110eee44444444444444ee44444444444444e
ee000000000000eee0aa08877880aa0eeee0500ee0050eeee00bbbbbbbbbb00e1111115555111111ee01111ee11110eee44444444444444e44fff444444fff44
fe000000000000ef0550082882800550eee0500ee0050eeee0bbbbbbbbbbbb0e1111100555111111ee01111ee11110eee44444444444444e4ffffff44ffffff4
f000ff0000ff000f0550088228800550eee0500ee0050eeeb0bbbbbbbbbbbb0b1110115555110111ee01111ee11110eee44499444499444e4ffffffffffffff4
f00ffff00ffff00f0550008778000550eee0500ee0050eeeb3bb33333333bb3b1110115555110111ee01111ee11110eee44449944994444e4ffffffffffffff4
f00f00ffff00f00f0550007777000550eee0500ee0050eeeeb3b300bb003b3be1110100555110111ee01111ee11110eee44444444444444e4ffffffffffffff4
e0ff780ff087ff0e0550007777000550eee0500ee0050eeeee3bb00bb00bb3ee1110115555110111ee01111ee11110eee44444400444444e44ffffffffffff44
eeff788ff887ffee0555007777005550eee0500ee0050eeeeeebbbbbbbbbbeee1110115555110111ee01111ee11110eeee444444444444ee44ffffffffffff44
eeffffffffffffee0555707777075550eee0500ee0050eeeeeebbbbbbbbbbeee1110100555110111ee01111ee11110eeee444074470444eee44ffffffffff44e
eeeff07ff70ffeee0555577777755550eee7000ee0007eeeeeebbb2222bbbeee1110115555110111e550011ee110055eeee4400770044eeeee44ffffffff44ee
eeeef070070feeeee05555777755550ee000777ee777000eee6ebb2222bbe6eeeee1115555111eee5005000ee0005005eee4470000744eeeee44ffffffff44ee
eeeeef0000feeeeeee005555555500ee0000000ee0000000ee665b2bb2b566eeeee1115555111eee0000000ee0000000eeee44777744eeeeeee44ffffff44eee
eeeeeeffffeeeeeeeeee00000000eeee0000000ee0000000ee6eebbbbbbee6eeeee1115555111eee0000000ee0000000eeeee444444eeeeeeeee447fff44eeee
eeeeeeee44eeeeeeeeeeeeeeeeeeeeeeeeeee445444eeeee0000000000000000000000000000000000000000000000000000000000000000ee44444ee44444ee
eeeeeee444eeeeeeeee5e44e454eeeeeeeee44544444eeee0000000000000000000000000000000000000000000000000000000000000000e44444eeee44444e
ee9999e44d9999eeee544444554eeeeeeeee554eee44eeee0000000000000000000000000000000000000000000000000000000000000000e4444eeeeee4444e
e99999944999999eee44e44445454eeeeee544eeee444eee00000000000000000000000000000000000000000000000000000000000000004444eeeeeeee4444
9999999999999999ee45e4e4445454eeeeee44eeeee44eee00000000000000000000000000000000000000000000000000000000000000004444eeeeeeee4444
9999999999999999e45ee44e4e4e544eeeeee445eee44eee000000000000000000000000000000000000000000000000000000000000000044444eeeeee44444
9999a999999a9999e5eeee4eee4e5e4eeeee4445eee44eee0000000000000000000000000000000000000000000000000000000000000000e44444eeee44444e
999aaa9999aaa99954eeee44e4eeee4eeeeee45eeee44eee0000000000000000000000000000000000000000000000000000000000000000eee4444ee4444eee
999aaaa99aaaa999e45eee4ee4eeee4eeeeee54eeee44eee0000000000000000000000000000000000000000000000000000000000000000eeee444ee444eeee
9999aa9999aa9999e45eeee4e4eeee4eeeee54eeee44eeee0000000000000000000000000000000000000000000000000000000000000000eeee444ee444eeee
9999999999999999e544ee44454ee4d4eeee54eeee44eeee0000000000000000000000000000000000000000000000000000000000000000eeee444ee444eeee
999aaa999999aa99e45d4e44544ee4d4eeee44eeee4eeeee0000000000000000000000000000000000000000000000000000000000000000eee444eeee444eee
e9a9aaa9a9aaa99ee4e5ee45454e4e4ee4eee44eee4eeeee0000000000000000000000000000000000000000000000000000000000000000eee444eeee444eee
e9999aaaaaaa999eeee5e44544eeeeee4e4ee44eee44ee4e0000000000000000000000000000000000000000000000000000000000000000ee444eeeeee444ee
ee9999a9aa9a99eeee5ee44544eeeeee4eee44eeeee44ee40000000000000000000000000000000000000000000000000000000000000000e4444eeeeee4444e
eeee99999999eeeeeeeee4544eeeeeeee4444eeeeee4444d00000000000000000000000000000000000000000000000000000000000000000404eeeeeeee4040
__label__
aaa1aaa11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111aaa1aaa1
11a1a1a11111111111111111111111111111111111aa11aaa1aaa1a1a11111aaa111111aa1aaa1aaa1aa11111111111111111111111111111111111111a1a1a1
aaa1a1a11111111111111111111111111111111111a1a1a1a1a1a1a1a11111a1a11111a111a1a1a1a1a1a11111111111111111111111111111111111aaa1a1a1
a111a1a11111111111111111111111111111111111a1a1aa11aaa1a1a11111aaa11111a111aaa1aa11a1a11111111111111111111111111111111111a111a1a1
aaa1aaa11111111111111111111111111111111111a1a1a1a1a1a1aaa11111a1a11111a111a1a1a1a1a1a11111111111111111111111111111111111aaa1aaa1
111111111111111111111111111111111111111111aaa1a1a1a1a1aaa11111a1a111111aa1a1a1a1a1aaa1111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111a11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111a111111111111111111111111111
1111111111aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11116666666666661111111777777777777111111117777777777771111111177777777777711111111777777777777111111111111111111111111111111111
1116ddddd121dddd6111117222222222222711111173333333333337111111722222222222271111117dddddddddddd711111111111111111111111111111111
116dd1111121111dd6111722227777772222711117333333bb33333371111722227777772222711117dddddddddddddd71111111111111111111111111111111
166d111111211111d61117222211111122227111173333377773333371111722221111112222711117ddddd00000dddd71111111111111111111111111111111
666d111112118111d61117222211111122227111173333bbb773333371111722221111112222711117dddd000000dddd71111111111111111111111111111111
666d111112118111d6111722221111112222711117333bbbb773333371111722221111112222711117dddd000000dddd71111111111111111111111111111111
666d111121111811d6111722221111112222711117333bbb7773333371111722221111112222711117ddd0007777dddd71111111111111111111111111111111
666d111211111811d611172222111c112222711117333bbb777333337111172222111c112222711117ddd7007767dddd71111111111111111111111111111111
666d112111111811d611172222111c112222711117333bbb777333337111172222111c112222711117ddd7077707dddd71111111111111111111111111111111
666d112111118111d611172222111c112222711117333bbb777333337111172222111c112222711117ddd7777707dddd71111111111111111111111111111111
666d111211181111d611172222111c112222711117333bbb777333337111172222111c112222711117ddd0777777dddd71111111111111111111111111111111
666d111118811111d611172222111c1122227111173333bb7bbb33337111172222111c112222711117ddd0077777dddd711111111111111111c1111111111111
666d111181111111d611172222111c1122227111173333bbbbbb33337111172222111c112222711117dddd077788dddd711111111111111111cc111111111111
666d111811112111d611172222114414442271111733333bbbbb333371111722221144144422711117ddddd77777dddd711111111111111111ccc11111111111
666d118111111211d61117222244444144427111173333377773333371111722224444414442711117dddddd77dddddd711111111111111111cccc1111111111
666d118111111211d61117222244444144427111173333377773333371111722224444414442711117dddddd77dddddd711111111111111111cc111111111111
666d118111112111d611177777777777777771111777777777777777711117777777777777777111177777777777777771111111111111111511555111111111
666d111811121111d611178282111226211171111783831113363111711117828211122621117111178d8d111dd6d11171111111111111111155111111111111
666d111811211111d61117888222122622217111178883331336333171111788822212262221711117888d1dddd6d1dd71111111111111111111111111111111
666d111111211111d61117888211122621117111178883111336311171111788821112262111711117888d111dd6d11171111111111111111111111111111111
666d111112111111d61117888212225551227111178883133355513371111788821222555122711117888ddd1d555dd171111111111111111111111111111111
666dd1111211111dd61117282211122421117111173833111334311171111728221112242111711117d8dd111dd4d11171111111111111111111111111111111
66d6dddd121ddddd6111117222222222222711111173333333333337111111722222222222271111117dddddddddddd711111111111111111111111111111111
6d6d6666666666661111111777777777777111111117777777777771111111177777777777711111111777777777777111111111111111111111111111111111
16d66666666666611111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11666666666666111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__sfx__
000100000000000000000000000000000110501405016050170501b0501e0502005022050240502505027050290502c0502e05000000000000000000000000000000000000000000000000000000000000000000
181800002472224722247122471227722277122b7222b72200702007020070200702007020070200702007022472224722247122471228722287222b7222b7120070200702007020070200702007020070200702
19180000247122471227722277122b7222b7122472224712277322772224722247122b7222b7220070200702247222471228722287122b7222b7222472224712287222871224722247122b7222b7220070200702
31180000187151b7251f735187151b7251f735187151b725187151b7251f735187151b7251f735187151b725187151c7251f735187151c7251f735187151c725187151c7251f735187151c7251f735187151c725
311800000c73200000000000c72213742137420c722000000c73200000000000c72200000000000c722000000c73200000000000c72213742137420c722000000c73200000000000c72200000000000c72200000
191800000c73500005000050c72513705137050c725000050c73500005000050c72500005000050c725000050c73500005000050c72513705137050c725000050c73500005000050c72500005000050c72500005
1918000018700187001c7001c700137421373218700187001c7001c7001f7001f70018700187001c7001c70018700187001c7001c700137421373218700187001c7001c7001f7001f70018700187001c7001c700
1b18000024700247001374213732277002770027700277002b7002b70013742137322470024700247002470027700277001374213732247002470024700247002b7002b700137421373224700247002470024700
1918000013752137420c73213752137420c7320c732000020f7520f7420f7320f732137521374213742137222b7222b712247122b7222b712247122471224002277222772227712277122b7222b7222b7122b712
0118000024722247220c7320c7322b7222b72213732137322b7220c732247220f7322b7221373224722007022b7222b7222b7222b72224722247222472224722137421374200000007020c7420c7420000000000
0118000000000000000000000000000000000000000000000000000000000000000000000000000000000000137321373213732137320c7320c7320c7320c7320c70200000287222872200000000000000000000
000100000000000000000000000000000110501405016050170501b0501e0502005022050240502505027050290502c0502e05000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300002a65027650226501d65018650126500e65009650046500365000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000300002a15027150221501d15018150121500e15009150041500315000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
000400000d0500d0500e050150501a050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000015050110500e0500a0500a050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0004000015150111500e1500a1500a150001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100
00030000086500865008650086500865008650086500a6500c6500f65014650106500f6500e6500d6500e65011650166501b6501e650000000000000000000000000000000000000000000000000000000000000
000200002055000000000001f55000000000001a5500000000000165501a500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 40454205
01 41460305
01 01060305
02 02070305
01 01060305
02 01060204
02 41420204
02 41424304


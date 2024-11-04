pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
function _init()
 state='game'
 game_state='draw_one'
 -- setup mouse
 poke(0x5f2d, 1)
 mouse={}
 players={
  new_player(1),
  new_player(2),
 }
 cards={
  new_card(30,90,'frank_head',1),
  new_card(50,90,'frank_body',1),
  new_card(70,90,'frank_legs',1),
  new_card(90,90,'frank_legs',1),
 }
 deck=new_deck(1)
end

function new_card (x,y,t,p)
 local card={
  p=p,
  x=x,
  y=y,
  w=2*8,
  h=3*8,
  placed=false,
  draw=function(self)
   spr(self.s,self.x,self.y,2,2)
   spr(3,self.x,self.y+16,2,1)
   print(self.hp,self.x+5,self.y+17,1)
   print(self.hp,self.x+12,self.y+17,1)
  end,
 }
 for k,v in pairs(card_data[t]) do
  card[k]=v
 end
 return card
end
function new_deck (p)
 return {
  x=10,
  y=90,
  w=2*8,
  h=3*8,
  draw=function(self)
   spr(14,self.x,self.y,2,3)
  end,
  on_click=function(self)
  end,
 }
end
function new_player (num)
 return {
  num=num,
 }
end
function collide (e1,e2)
 return e1.x+(e1.w or 0)>e2.x and
        e1.x<e2.x+(e2.w or 0) and
        e1.y+(e1.h or 0)>e2.y and
        e1.y<e2.y+(e2.h or 0)
end

function _update60()
 game_state_msg=nil
 hover_card=nil
 mouse.x=stat(32)
 mouse.y=stat(33)
 foreach(cards,function(c)
  if collide(mouse,c) then
   hover_card=c
   return
  end
 end)
 if state=='game' then
  if game_state=='draw_one' then
   game_state_msg='draw a card'
   if stat(34)==1 and
      collide(mouse,deck) then
    new_card(110,90,'frank_legs',1)
    game_state='play_one'
    return
   end
  elseif game_state=='play_one' then
   game_state_msg='play a card' 
   -- mouse down
   if stat(34)==1 then
    -- are we holding a card?
    if held_card then
     held_card.x=mid(mouse.x-held_offset_x,20,100)
     held_card.y=mid(mouse.y-held_offset_y,40,120)
    else
     -- are we picking up a card?
     foreach(cards,function(c)
      if not c.placed and
         collide(mouse,c) then
       held_card=c
       held_offset_x=mouse.x-c.x
       held_offset_y=mouse.y-c.y
      end
     end)
    end
   else
    held_card=nil
    spr(1,mouse.x,mouse.y)
   end
  elseif game_state=='discard_one' then
   game_state_msg='discard a card'
  elseif game_state=='deal_damage' then
  end
 end
end

function _draw ()
 cls(1)
 deck:draw()
 foreach(cards,function(c)
  c:draw()
 end)
 if held_card then
  rectfill(held_card.x+1,
           held_card.y+1,
           held_card.x+2*8,
           held_card.y+3*8+1,0)
  held_card:draw()
 end
 -- draw mouse
 if stat(34)==1 then
  spr(2,mouse.x,mouse.y)
 else
  spr(1,mouse.x,mouse.y)
 end
 if game_state_msg then
  cprint(game_state_msg,64,
         sin(time())+.1+10,10)
 end
 if hover_card and
    not held_card then
  cprint(hover_card.name,64,120, 10)
 end
 if held_card then
  cprint(held_card.name,64,120,10)
 end
end

function cprint(msg,x,y,c)
 print(msg,x-#msg*2,y,c)
end
-->8
card_data={
 frank_head={
  name='frankenstein - head',
  s=16,
  hp=2,
  atk=2,
 },
 frank_body={
  name='frankenstein - body',
  s=18,
  hp=2,
  atk=2,
 },
 frank_legs={
  name='frankenstein - legs',

  s=20,
  hp=2,
  atk=2,
 },
}
__gfx__
000000000c0000000c00000077777777777777770000000000000000000000000000000000000000000000000000000000000000000000000066666666666600
00000000c0c00000cdc0000078f8ffffff6ffff700000000000000000000000000000000000000000000000000000000000000000000000006ddddd121dddd60
00700700c00c0000cddc00007888ffffff6ffff70000000000000000000000000000000000000000000000000000000000000000000000006dd1111121111dd6
00077000c000c000cdddc0007888ffffff6ffff70000000000000000000000000000000000000000000000000000000000000000000000006d111111211111d6
00077000c0000c00cddddc007888fffff555fff70000000000000000000000000000000000000000000000000000000000000000000000006d111112118111d6
00700700c00000c0cdddddc07f8fffffff4ffff70000000000000000000000000000000000000000000000000000000000000000000000006d111112118111d6
00000000c00cccc0cddcccc007ffffffffffff700000000000000000000000000000000000000000000000000000000000000000000000006d111121111811d6
000000000ccc00000ccc000000777777777777000000000000000000000000000000000000000000000000000000000000000000000000006d111211111811d6
00777777777777000077777777777700007777777777770000000000000000000000000000000000000000000000000000000000000000006d112111111811d6
07ffffffffffff7007ffffffffffff7007ffffffffffff7000000000000000000000000000000000000000000000000000000000000000006d112111118111d6
7fffff33333ffff77ffffffbbffffff77ffff777777ffff700000000000000000000000000000000000000000000000000000000000000006d111211181111d6
7ffff333333ffff77fffff7777fffff77ffff111111ffff700000000000000000000000000000000000000000000000000000000000000006d111118811111d6
7fff3333333ffff77ffffbbb77fffff77ffff111111ffff700000000000000000000000000000000000000000000000000000000000000006d111181111111d6
7fff3333bbbffff77fffbbbb77fffff77ffff111111ffff700000000000000000000000000000000000000000000000000000000000000006d111811112111d6
7fff33b3b7bffff77fffbbb777fffff77ffff111111ffff700000000000000000000000000000000000000000000000000000000000000006d118111111211d6
7fff33bbb1bffff77fffbbb777fffff77ffff111c11ffff700000000000000000000000000000000000000000000000000000000000000006d118111111211d6
7fff3bbbb1bffff77fffbbb777fffff77ffff111c11ffff700000000000000000000000000000000000000000000000000000000000000006d118111112111d6
7ffffbbbbbbffff77fffbbb777fffff77ffff111c11ffff700000000000000000000000000000000000000000000000000000000000000006d111811121111d6
7ff55bbbbbbffff77fffbbb777fffff77ffff111c11ffff700000000000000000000000000000000000000000000000000000000000000006d111811211111d6
7ff5566bb44ffff77ffffbb7bbbffff77ffff111c11ffff700000000000000000000000000000000000000000000000000000000000000006d111111211111d6
7ff5566bbbbffff77ffffbbbbbbffff77ffff111c11ffff700000000000000000000000000000000000000000000000000000000000000006d111112111111d6
7ff55bbbbbbffff77fffffbbbbbffff77ffff11441444ff700000000000000000000000000000000000000000000000000000000000000006dd1111211111dd6
7ffffffbbbfffff77fffff7777fffff77ffff444441444f7000000000000000000000000000000000000000000000000000000000000000006dddd121ddddd60
7ffffffbbbfffff77fffff7777fffff77ffff444441444f700000000000000000000000000000000000000000000000000000000000000000066666666666600
__sfx__
000100000000000000000000000000000110501405016050170501b0501e0502005022050240502505027050290502c0502e05000000000000000000000000000000000000000000000000000000000000000000

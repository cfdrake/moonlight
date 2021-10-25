-- moonlight
--
-- based on first light: @tehn
-- l.llllllll.co/firstlight

g = grid.connect()

-- make a table of numbers, along with variables
-- to track length and current position
numbers = {3,1,8,5,1,2,3,4,1,7,2,1,8,6,4,2}
length = 6
pos = 0

edit = 1 -- which number we're editing

-- on/off for stepped sequence
sequence = true
edit_mode = false
freeze = false
clock_rate = 1
delay_size = 1
pre_level = 0.85

-- system clock tick
-- this function is started by init() and loops forever
-- if the sequence is on, it steps forward on each tick
-- tempo is controlled via the global clock, which can be set in the PARAM menu 
tick = function()
  while true do
    clock.sync(1/clock_rate)
    if sequence then step() end
  end
end

-- sequence step forward
-- advance the position and do something with the number
step = function()
  pos = util.wrap(pos+1,1,length)
  --[[ 0_0 ]]--
  softcut.loop_end(1, numbers[pos] / math.pow(2, delay_size))
end

--------------------------------------------------------------------------------
-- init runs first!
function init()
  -- configure the delay
  audio.level_cut(1.0)
  audio.level_adc_cut(1)
  audio.level_eng_cut(1)
  softcut.level(1,1.0)
  softcut.level_slew_time(1,0.25)
  softcut.level_input_cut(1, 1, 1.0)
  softcut.level_input_cut(2, 1, 1.0)
  softcut.pan(1, 0.0)
  softcut.play(1, 1)
  softcut.rate(1, 1)
  softcut.rate_slew_time(1,1.0)
  softcut.loop_start(1, 0)
  softcut.loop_end(1, 0.5)
  softcut.loop(1, 1)
  -- softcut.fade_time(1, 0.1)
  softcut.rec(1, 1)
  softcut.rec_level(1, 1)
  softcut.pre_level(1, pre_level) --[[ 0_0 ]]--
  softcut.position(1, 0)
  softcut.enable(1, 1)
  softcut.filter_dry(1, 0);
  softcut.filter_lp(1, 1.0);
  softcut.filter_bp(1, 1.0);
  softcut.filter_hp(1, 1.0);
  softcut.filter_fc(1, 300);
  softcut.filter_rq(1, 2.0);

  clock.run(tick)       -- start the sequencer

  clock.run(function()  -- redraw the screen and grid at 15fps
    while true do
      clock.sleep(1/15)
      redraw()
      gridredraw()
    end
  end)

  norns.enc.sens(1,8)   -- set the knob sensitivity
  norns.enc.sens(2,4)
end


--------------------------------------------------------------------------------
-- encoder
function enc(n, delta)
  
  
  if edit_mode then
    if n==1 then
      -- E1 change the length of the sequence
      length = util.clamp(length+delta,1,16)
      edit = util.clamp(edit,1,length)
    elseif n==2 then
      -- E2 change which step to edit
      edit = util.clamp(edit+delta,1,length)
    elseif n==3 then
      -- E3 change the step value
      numbers[edit] = util.clamp(numbers[edit]+delta,1,8)
    end
  else
    if n == 1 then
      clock_rate = util.clamp(clock_rate + delta, 1, 4)
    elseif n == 2 then
      delay_size = util.clamp(delay_size + delta, 1, 4)
    elseif n == 3 then
      pre_level = util.clamp(pre_level + delta / 100, 0, 1)
      softcut.pre_level(1, pre_level)
    end
  end
end


--------------------------------------------------------------------------------
-- key
function key(n,z)
  if n == 1 and z == 1 then
    edit_mode = not edit_mode
  end
  
  if not edit_mode then
    if n==3 and z==1 then
      freeze = not freeze
      
      if freeze then
        softcut.rec(1, 0)
        softcut.pre_level(1, 1)
      else
        softcut.pre_level(1, pre_level)
        softcut.rec(1, 1)
      end
    elseif n==2 and z==1 then
      --[[ 0_0 ]]--
      sequence = not sequence
    end
  end
end


--------------------------------------------------------------------------------
-- screen redraw
function redraw()
  screen.clear()
  screen.line_width(1)
  screen.aa(0)

  -- draw bars for numbers
  offset = 64 - length*2
  for i=1,length do
    screen.level(i==pos and 15 or 1)
    screen.move(offset+i*4,60)
    screen.line_rel(0,numbers[i]*-4+-1)
    screen.stroke()
  end

  -- draw edit position
  if edit_mode then
    screen.level(10)
    screen.move(offset+edit*4,62)
    screen.line_rel(0,2)
    screen.stroke()
  end

  -- screen ind
  screen.level(5)
  screen.move(0, 10)
  screen.text(edit_mode and "EDIT" or "PLAY")
  
  if not edit_mode then
    
    -- clk
    screen.move(50, 10)
    screen.level(3)
    screen.text("clk")
    screen.move(64, 10)
    screen.level(10)
    screen.text(clock_rate)
    
    -- del
    screen.move(74, 10)
    screen.level(3)
    screen.text("sp")
    screen.move(88, 10)
    screen.level(10)
    screen.text(delay_size)
    
    -- fb
    screen.move(98, 10)
    screen.level(3)
    screen.text("fb")
    screen.move(110, 10)
    screen.level(10)
    screen.text(math.floor(pre_level * 100))
    
    -- seq ind
    screen.move(0, 30)
    screen.level(3)
    screen.text("seq")
    screen.move(0, 40)
    screen.level(10)
    screen.text(sequence and "play" or "pause")
    
    -- freeze ind
    screen.move(0, 50)
    screen.level(3)
    screen.text("buffer")
    screen.move(0, 60)
    screen.level(10)
    screen.text(freeze and "freeze" or "delay")
    
  else
    
    -- len
    screen.move(0, 50)
    screen.level(3)
    screen.text("length")
    screen.move(0, 60)
    screen.level(10)
    screen.text(length)
    
  end

  screen.update()
end

--------------------------------------------------------------------------------
-- grid key
function g.key(x, y, z)
  if z > 0 then
    numbers[x] = 9-y
  end
end

-- grid redraw
function gridredraw()
  g:all(0)
  for i=1,length do
    g:led(i,9-numbers[i],i==pos and 15 or 3)
  end
  g:refresh()
end
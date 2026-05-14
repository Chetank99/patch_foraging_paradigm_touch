eventmarker(1); % Trial Start
global MyTask;

% --- TASK TUNING PARAMETERS ---
initialrew_base = 7;    % Change to set starting berry reward in a new patch
dec_val = 0.5;          % Change to set harvest depletion amount per pick
noise_sigma = 0.25;     % Change to set reward noise standard deviation

% Functions for Reward Dynamics
get_initial_rew = @() initialrew_base + noise_sigma * randn();
get_next_rew = @(prev) prev - dec_val + noise_sigma * randn();

% --- TIMING & SOLENOID PARAMETERS ---
handling_time=20;       % Post-choice delay before trial end (ms)
holdtime_base = 1000;   % Base fixation duration
get_holdtime = @() 750 + (1500-750)*rand(); % Jittered hold duration range (ms)

fix_reward = 75;        % Solenoid reward duration for acquiring fixation (ms)
explore_Reward = 100;   % Solenoid reward duration for traveling (ms)
wait_for_fix = 35000;   % Max time allowed for monkey to make a decision (ms)
initial_fix = 5000000000000000;
resp_time = 4000;
to=10;

% --- PERSISTENT TRACKING ---
persistent prev_feedback_ids;
if isempty(prev_feedback_ids); prev_feedback_ids = []; end
persistent gate_done;
if isempty(gate_done); gate_done = 0; end
persistent last_cursor;
if isempty(last_cursor); last_cursor = 17; end 

% --- SELECT CAR BASED ON BLOCK (MODULAR) ---
if TrialRecord.CurrentBlock == 1
    cursor_obj = 17; last_cursor = 17;
elseif TrialRecord.CurrentBlock == 2
    cursor_obj = 18; last_cursor = 18;
elseif TrialRecord.CurrentBlock == 3 || TrialRecord.CurrentBlock == 4
    cursor_obj = last_cursor; 
elseif TrialRecord.CurrentBlock == 5
    cursor_obj = 17; 
else
    cursor_obj = 16; 
end

is_break_block = (TrialRecord.CurrentBlock == 3);
is_instruction_block = (TrialRecord.CurrentBlock == 4);
is_practice_block = (TrialRecord.CurrentBlock == 5);

if isempty(MyTask)
    MyTask = struct('cumswitch', 0, 'currentReward', get_initial_rew(), 'exploreflag', 0, 'exploitCounter', 0, 'trial_switch', 0, 'condilist', [], 'm', 1, 'currentBlockTracker', 0);
end

% --- BLOCK CHANGE CLEANUP ---
if TrialRecord.CurrentTrialNumber <= 1 || TrialRecord.CurrentBlock ~= MyTask.currentBlockTracker
    MyTask.currentBlockTracker = TrialRecord.CurrentBlock;
    MyTask.cumswitch = 0; MyTask.currentReward = get_initial_rew();
    if ~isempty(prev_feedback_ids)
        for tid = prev_feedback_ids; try mglsetproperty(tid, 'active', 0); catch; end; end
        prev_feedback_ids = [];
    end
end

% --- START GATE LOGIC ---
if TrialRecord.CurrentBlock == 1 && gate_done == 0
    gate_car = 17; toggleobject(1:19, 'status', 'off'); toggleobject(gate_car, 'status', 'on');
    text_id = mgladdtext('Keep your car on the circle to start');
    mglsetproperty(text_id, 'origin', [600 540], 'fontsize', 18, 'color', [1 1 1], 'angle', 90, 'halign', 2, 'bold', 1, 'active', 1);
    reposition_object(3, 0, 0); toggleobject(3, 'status', 'on');
    h = 0; start_time = trialtime; current_hold = get_holdtime();
    while h == 0
        xy = mouse_position(); reposition_object(gate_car, xy(1), xy(2));
        dist = sqrt(xy(1)^2 + xy(2)^2);
        if dist < 2; if (trialtime - start_time) > current_hold; h = 1; end; else; start_time = trialtime; end
        idle(1);
    end
    mglsetproperty(text_id, 'active', 0); toggleobject([3 gate_car], 'status', 'off'); gate_done = 1; 
end

% --- GARAGE BREAK LOGIC ---
if is_break_block
    toggleobject(1:19, 'status', 'off'); toggleobject(cursor_obj, 'status', 'on');
    text_id = mgladdtext('Keep your car here for 5 seconds');
    mglsetproperty(text_id, 'fontsize', 24, 'origin', [600 540], 'color', [1 1 1], 'angle', 90, 'halign', 2, 'bold', 1, 'active', 1);
    reposition_object(3, 0, 0); toggleobject(3, 'status', 'on');
    h = 0; start_time = trialtime;
    while h == 0
        xy = mouse_position(); reposition_object(cursor_obj, xy(1), xy(2));
        dist = sqrt(xy(1)^2 + xy(2)^2);
        if dist < 5; if (trialtime - start_time) > 5000; h = 1; end; else; start_time = trialtime; end
        idle(1);
    end
    mglsetproperty(text_id, 'active', 0); toggleobject([3 cursor_obj], 'status', 'off');
    trialerror(0); return;
end

% --- INSTRUCTION BLOCK LOGIC ---
if is_instruction_block
    toggleobject(1:19, 'status', 'off'); toggleobject(cursor_obj, 'status', 'on');
    p1 = {'Goal: Collect as many berries as you can.',' ','1. Hover on the BOX until it fills up.','(You may need to wiggle your mouse)',' ','More berries = More reward!'};
    p2 = {'Each trial: Stay or Leave.',' ','To PICK: Hover on the BUSH.','Reward numbers show your harvest.',' ','Bushes DEPLETE as you pick!'};
    p3 = {'To LEAVE: Hover on the BOX.',' ','TRAVEL takes time, but resets bush value.',' ','Study: 2 sessions. Car changes once!','Limited trials to maximize points!'};
    pages = {p1, p2, p3};
    
    current_page = 1;
    while current_page <= length(pages)
        % Clear previous stims and keep car on
        toggleobject(1:19, 'status', 'off');
        toggleobject(cursor_obj, 'status', 'on');
        
        % Display text lines
        current_lines = pages{current_page};
        text_ids = [];
        for li = 1:length(current_lines)
            tid = mgladdtext(current_lines{li});
            % Stack lines side-by-side (Physical Top -> Landscape Right to Left)
            % Center horizontally on vertical screen (Landscape Y = 540)
            x_offset = 1400 - (li-1) * 60;
            mglsetproperty(tid, 'origin', [x_offset 540], 'fontsize', 18, 'color', [1 1 1], 'angle', 90, 'halign', 2, 'bold', 1, 'active', 1);
            text_ids(end+1) = tid;
        end
        
        % Final calibrated positions for vertical monitor
        % NEXT: Physical Bottom-Right (Landscape Bottom-Right)
        % BACK: Physical Top-Right (Landscape Top-Right)
        next_px = [1770 950]; back_px = [1770 150];
        ppd = MLConfig.Screen.PixelsPerDegree;
        sz = [MLConfig.Screen.Xsize MLConfig.Screen.Ysize];
        
        next_id = mgladdtext('NEXT >');
        mglsetproperty(next_id, 'origin', next_px, 'fontsize', 16, 'color', [0 1 0], 'angle', 90, 'halign', 2, 'bold', 1, 'active', 0);
        
        back_id = 0;
        if current_page > 1
            back_id = mgladdtext('< BACK');
            mglsetproperty(back_id, 'origin', back_px, 'fontsize', 16, 'color', [1 0 0], 'angle', 90, 'halign', 2, 'bold', 1, 'active', 0);
        end
        
        % Add stimuli based on page
        if current_page == 1
            reposition_object(1, 0, 0); toggleobject(1, 'status', 'on'); % Use Square Box
        elseif current_page == 2
            reposition_object(4, 15, 0); toggleobject(4, 'status', 'on'); % Bush
        elseif current_page == 3
            sq_px = [1000 540]; sq_deg = (sq_px - sz/2) ./ ppd;
            reposition_object(1, sq_deg(1), sq_deg(2)); toggleobject(1, 'status', 'on');
            car_px = [1000 700]; car_deg = (car_px - sz/2) ./ ppd;
            reposition_object(cursor_obj, car_deg(1), car_deg(2)); toggleobject(cursor_obj, 'status', 'on');
        end
        
        % INTERACTIVE GATE: Wait for user to interact with the relevant stimulus
        target_hover_start = 0;
        while true
            xy = mouse_position(); reposition_object(cursor_obj, xy(1), xy(2)); 
            
            % Identify page target in degrees
            if current_page == 1; target_pos = [0 0];
            elseif current_page == 2; target_pos = [15 0];
            else; target_pos = sq_deg;
            end
            
            % Check hover on target
            if sqrt((xy(1)-target_pos(1))^2 + (xy(2)-target_pos(2))^2) < 4
                if target_hover_start == 0; tic; target_hover_start = 1; end
                if toc > 0.5; break; end % Required 500ms hover
            else
                target_hover_start = 0;
            end
            idle(1);
        end
        
        % Reveal buttons and reward text after successful interaction
        mglsetproperty(next_id, 'active', 1);
        if back_id > 0; mglsetproperty(back_id, 'active', 1); end
        
        % For Window 2, show reward only after hover
        if current_page == 2
            rew_id = mgladdtext('+1.83');
            mglsetproperty(rew_id, 'origin', [1560 540], 'fontsize', 24, 'color', [1 1 1], 'angle', 90, 'halign', 2, 'bold', 1, 'active', 1);
            text_ids(end+1) = rew_id;
        end
        
        button_clicked = 0;
        while button_clicked == 0
            xy_deg = mouse_position(); 
            reposition_object(cursor_obj, xy_deg(1), xy_deg(2)); showcursor('off'); 
            
            % Convert mouse degrees to pixels
            xy_px = xy_deg .* ppd + sz/2;
            
            % Direct pixel hover check (80px radius for precision)
            % Internal coordinates are vertically flipped relative to visual POV
            dist_internal_next_target = sqrt((xy_px(1)-back_px(1))^2 + (xy_px(2)-back_px(2))^2);
            dist_internal_back_target = sqrt((xy_px(1)-next_px(1))^2 + (xy_px(2)-next_px(2))^2);
            
            if dist_internal_next_target < 80
                current_page = current_page + 1; button_clicked = 1; idle(400); 
            elseif current_page > 1 && dist_internal_back_target < 80
                current_page = current_page - 1; button_clicked = 1; idle(400); 
            end
            idle(1);
        end
        
        % Cleanup page
        for tid = text_ids; mglsetproperty(tid, 'active', 0); end
        mglsetproperty(next_id, 'active', 0);
        if back_id > 0; mglsetproperty(back_id, 'active', 0); end
    end
    toggleobject(1:19, 'status', 'off'); trialerror(0); return;
end

dashboard(2, sprintf('Current Reward: %.2f', MyTask.currentReward));
global toflag; showcursor('on'); try ShowCursor; catch; end
try mouse_tracker = MouseTracker(TrialRecord); mouse_tracker.showcursor(true); catch; end

fix_pos = [15, 0]; stay_x = 15; leave_x = 15;            
exploitr_pos = [stay_x, 5]; explorel_pos = [leave_x, -5];  
exploitl_pos = [stay_x, -5]; explorer_pos = [leave_x, 5];   

global distances; global coor;
occluder = 1; fixation_pointg = 2; fixation_point = 3;
mexploitr = 4; mexplorel = 5; mexploitl = 6; mexplorer = 7; mexplore1 = 8;
exploitr = 9; explorel = 10; exploitl = 11; explorer = 12; explore1 = 13;
fixation_pointgr = 14; road = 15;

% --- TRAVEL DURATION SETTINGS ---
% Change the values in 'delays' array to set travel time (in milliseconds) per condition/block
if TrialRecord.CurrentBlock==1
    delays=[3000,3000,3000,3000,3000,3000]; hz=60; % Change to alter Fast Forest travel time
elseif TrialRecord.CurrentBlock==2
    delays=[9000,9000,9000,9000,9000,9000]; hz=60; % Change to alter Slow Forest travel time
elseif TrialRecord.CurrentBlock==5
    delays=[3000,3000,3000,3000,3000,3000]; hz=60; % Practice block travel time
else
    delays=[5000,5000,5000,5000,5000,5000]; hz=60; % Default / fallback travel time
end

fix_radius = 2; fixdelay = 20; 
coor=[-2, -2, -2, -2, -2, -2];
distances = [10, 10, 10, 10, 10, 10]; 
editable('fix_radius','fixdelay','wait_for_fix')

bush_ids = [4, 5, 6, 7, 9, 10, 11, 12];
dist_step = distances(TrialRecord.CurrentCondition);
base_x = [stay_x, stay_x-10.0, stay_x-20.0, stay_x-30.0, stay_x-40.0, stay_x-50.0, stay_x-60.0, stay_x-70.0];
if mod(MyTask.cumswitch,2)==1; base_y = [5, -5, 5, -5, 5, -5, 5, -5]; box_y = -5;
else; base_y = [-5, 5, -5, 5, -5, 5, -5, 5]; box_y = 5; end

for b = 1:8; reposition_object(bush_ids(b), base_x(b), base_y(b)); end
reposition_object(fixation_pointgr, fix_pos(1), fix_pos(2));
reposition_object(fixation_pointg, fix_pos(1), fix_pos(2));
reposition_object(1, leave_x, box_y);
toggleobject([bush_ids fixation_pointgr 1 cursor_obj]) 

h=0;
while h==0
    % Stage 1: Wait for Acquisition
    acquired = 0;
    while acquired == 0
        xy = mouse_position(); reposition_object(cursor_obj, xy(1), xy(2)); idle(1);
        if sqrt((xy(1) - fix_pos(1))^2 + (xy(2) - fix_pos(2))^2) <= fix_radius
            acquired = 1; eventmarker(3); % Fixation Start (Acquired)
        end
        % Clear feedback if any
        if ~isempty(prev_feedback_ids)
            for tid = prev_feedback_ids; try mglsetproperty(tid, 'active', 0); catch; end; end
            prev_feedback_ids = [];
        end
    end
    
    % Stage 2: Hold Fixation
    ontarget = 1; start_time = trialtime;
    current_hold = get_holdtime(); 
    while (trialtime - start_time) < current_hold
        xy = mouse_position(); reposition_object(cursor_obj, xy(1), xy(2)); idle(1);
        if sqrt((xy(1) - fix_pos(1))^2 + (xy(2) - fix_pos(2))^2) > fix_radius
            ontarget = 0; break; % Break Fixation
        end
    end
    
    if ontarget==1
        eventmarker(4); % Fixation End (Hold Success)
        toggleobject(fixation_pointgr, 'status', 'off'); 
        toggleobject(fixation_pointg, 'status', 'on'); 
        h=1; 
    end
end

idle(fixdelay);
if mod(MyTask.cumswitch,2)==1
    h=0;
    while h==0
        ontarget = 0; rt = 0; targets = [exploitr_pos; explorel_pos]; start_time = trialtime;
        if is_practice_block
            instr_id1 = mgladdtext('Hover on bush on left to pick');
            mglsetproperty(instr_id1, 'origin', [960 500], 'fontsize', 16, 'color', [1 1 1], 'angle', 90, 'halign', 2, 'bold', 1, 'active', 1);
            instr_id2 = mgladdtext('OR go to box right to travel to new bush');
            mglsetproperty(instr_id2, 'origin', [1000 500], 'fontsize', 16, 'color', [1 1 1], 'angle', 90, 'halign', 2, 'bold', 1, 'active', 1);
        end
        while (trialtime - start_time) < wait_for_fix
            xy = mouse_position(); reposition_object(cursor_obj, xy(1), xy(2)); idle(1);
            for k = 1:2; if sqrt((xy(1) - targets(k,1))^2 + (xy(2) - targets(k,2))^2) <= fix_radius; ontarget = k; rt = trialtime - start_time; break; end; end
            if ontarget > 0, break; end
        end
        if is_practice_block; mglsetproperty(instr_id1, 'active', 0); mglsetproperty(instr_id2, 'active', 0); end
        if ontarget==0; toflag=1; return; else; h=1; end
    end
else
    h=0;
    while h==0
        ontarget = 0; rt = 0; targets = [exploitl_pos; explorer_pos]; start_time = trialtime;
        if is_practice_block
            instr_id1 = mgladdtext('Hover on bush on left to pick');
            mglsetproperty(instr_id1, 'origin', [960 500], 'fontsize', 16, 'color', [1 1 1], 'angle', 90, 'halign', 2, 'bold', 1, 'active', 1);
            instr_id2 = mgladdtext('OR go to box right to travel to new bush');
            mglsetproperty(instr_id2, 'origin', [1000 500], 'fontsize', 16, 'color', [1 1 1], 'angle', 90, 'halign', 2, 'bold', 1, 'active', 1);
        end
        while (trialtime - start_time) < wait_for_fix
            xy = mouse_position(); reposition_object(cursor_obj, xy(1), xy(2)); idle(1);
            for k = 1:2; if sqrt((xy(1) - targets(k,1))^2 + (xy(2) - targets(k,2))^2) <= fix_radius; ontarget = k; rt = trialtime - start_time; break; end; end
            if ontarget > 0, break; end
        end
        if is_practice_block; mglsetproperty(instr_id1, 'active', 0); mglsetproperty(instr_id2, 'active', 0); end
        if ontarget==0; toflag=1; return; else; h=1; end
    end
end

if ontarget==1 
    eventmarker(5); trialerror(0);
    if TrialRecord.CurrentTrialNumber <= 1 || MyTask.currentBlockTracker ~= TrialRecord.CurrentBlock; currentReward = MyTask.currentReward;
    else; if toflag==0; currentReward = get_next_rew(MyTask.currentReward); else; currentReward = MyTask.currentReward; end; end
    toflag=0; MyTask.currentReward=currentReward;
    txt_x_pix = MLConfig.Screen.Xsize / 2 + 11 * MLConfig.Screen.PixelsPerDegree(1);
    txt_y_pix = MLConfig.Screen.Ysize / 2 - (mod(MyTask.cumswitch,2)*10-5) * MLConfig.Screen.PixelsPerDegree(1); 
    text_id = mgladdtext(sprintf('+%.2f', currentReward));
    mglsetproperty(text_id, 'color', [0 1 0], 'origin', [txt_x_pix txt_y_pix], 'fontsize', 40, 'bold', 1, 'right', 'angle', 90, 'active', 1);
    eventmarker(9); % Reward Display Start
    prev_feedback_ids(end+1) = text_id;
    if is_practice_block
        instr_id = mgladdtext('Enjoy your berries!');
        mglsetproperty(instr_id, 'origin', [960 500], 'fontsize', 18, 'color', [1 1 1], 'angle', 90, 'halign', 2, 'bold', 1, 'active', 1);
        prev_feedback_ids(end+1) = instr_id;
    end
    goodmonkey(max(0, currentReward)); 
    idle(500); eventmarker(6); % Reward Display End
else 
    eventmarker(8); trialerror(6); goodmonkey(explore_Reward);
    MyTask.trial_switch=1; MyTask.cumswitch = MyTask.cumswitch+1;
    MyTask.currentReward = get_initial_rew();
    duration = delays(TrialRecord.CurrentCondition); start_anim = trialtime;
    while (trialtime - start_anim) < duration
        t_progress = (trialtime - start_anim) / duration; current_offset = t_progress * dist_step;
        for b = 1:8; reposition_object(bush_ids(b), base_x(b) + current_offset, base_y(b)); end
        reposition_object(1, base_x(1) + current_offset, box_y);
        xy = mouse_position(); reposition_object(cursor_obj, xy(1), xy(2)); idle(1);
    end
    if is_practice_block
        instr_id = mgladdtext('Great! you came to a new patch after travel');
        mglsetproperty(instr_id, 'origin', [960 500], 'fontsize', 18, 'color', [0 1 0], 'angle', 90, 'halign', 2, 'bold', 1, 'active', 1);
        prev_feedback_ids(end+1) = instr_id;
        idle(3000); % Pause to allow reading during practice
    end
    for b = 1:8; reposition_object(bush_ids(b), base_x(b) + dist_step, base_y(b)); end
    reposition_object(1, base_x(1) + dist_step, box_y); toggleobject(1, 'status', 'off');
    eventmarker(6); % Travel End (Trial End)
end

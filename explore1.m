function [bushrepos1,xpos1,ypos1] = explore1(TrialRecord)

global MyTask;
if isempty(MyTask)
    MyTask = struct('cumswitch', 0, 'currentReward', 0, 'exploreflag', 0, 'exploitCounter', 0, 'trial_switch', 0, 'condilist', [], 'm', 1);
end

% Adjust initial spatial coordinates and travel step distances
coor=[-9.5, -22, -47];
distances = [12.5, 25, 50];

load imr
bushrepos1 = imr; % Pre-loaded bush image matrix

if TrialRecord.CurrentCondition <= length(coor)
    xpos1 = coor(TrialRecord.CurrentCondition);
else
    xpos1 = 15; % Default for break
end

if TrialRecord.CurrentTrialNumber <= 1
    ypos1=-5;
else
    
    if mod(MyTask.cumswitch,2)==1
        ypos1=5;
    else
        ypos1=-5;
    end
end
    
end


function [bushrepos1,xpos1,ypos1] = mexplore1(TrialRecord)

global MyTask;
if isempty(MyTask)
    MyTask = struct('cumswitch', 0, 'currentReward', 0, 'exploreflag', 0, 'exploitCounter', 0, 'trial_switch', 0, 'condilist', [], 'm', 1);
end

% Pre-load bush image matrix
load imr
bushrepos1 = imr;

% xpos1=coor(TrialRecord.CurrentCondition);
xpos1=-2;


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


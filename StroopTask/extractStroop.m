% run this script to extract parameters from the Stroop task
% assumes full dataset (all variants)
clearvars -except data loaded nameList excelName
close all

suiteNum = 3;

%% load in data and identify which variant is used into data{i,3}
%loads in data once to avoid the wait time of loading data for calculating
%parameters
if (~exist('loaded','var')) %only load data once 
    dataTemp = exam_load;
    for (i = 1:size(dataTemp,1))
        dataPre = KINARM_add_hand_kinematics(dataTemp(i).c3d); 
        dataPre = KINARM_add_jerk(dataPre);
        dataFilt = filter_double_pass(dataPre, 'enhanced', 'fc', 10);
        data{i,1} = dataTemp(i).filename; %participant name
        data{i,2} = dataFilt; %data
        data{i,3} = dataFilt(1).EXPERIMENT.TASK_PROTOCOL; %task variant
        clear dataPre dataFilt
    end
    loaded = 1; %do not load data again
end

%% calculate params
for (i = 1:size(data,1)) %go through each task run
    for (j = 1:size(data{i,2},2)) %go through each trial
        if (strcmp(data{i,2}(1).EXPERIMENT.ACTIVE_ARM,'RIGHT'))
            dataXPos = data{i,2}(j).Right_HandX; %xpos
            dataYPos = data{i,2}(j).Right_HandY; %ypos
            speedX = data{i,2}(j).Right_HandXVel;
            speedY = data{i,2}(j).Right_HandYVel;
            dataSpeed = hypot(data{i,2}(j).Right_HandXVel,data{i,2}(j).Right_HandYVel); %hand speed
            dataAccel = hypot(data{i,2}(j).Right_HandXAcc,data{i,2}(j).Right_HandYAcc); %hand acceleration
        else
            dataXPos = data{i,2}(j).Left_HandX; %xpos
            dataYPos = data{i,2}(j).Left_HandY; %ypos
            speedX = data{i,2}(j).Left_HandXVel;
            speedY = data{i,2}(j).Left_HandYVel;
            dataSpeed = hypot(data{i,2}(j).Left_HandXVel,data{i,2}(j).Left_HandYVel); %hand speed
            dataAccel = hypot(data{i,2}(j).Left_HandXAcc,data{i,2}(j).Left_HandYAcc); %hand acceleration
        end
        
        %get correct textcircle position number
        if (~isempty(data{i,2}(j).EVENTS.LABELS(find(contains(data{i,2}(j).EVENTS.LABELS,'STROOPC_RED')))))
            getPos(i,j) = 1;
        elseif (~isempty(data{i,2}(j).EVENTS.LABELS(find(contains(data{i,2}(j).EVENTS.LABELS,'STROOPC_BLUE')))))
            getPos(i,j) = 2;
        elseif (~isempty(data{i,2}(j).EVENTS.LABELS(find(contains(data{i,2}(j).EVENTS.LABELS,'STROOPC_GREEN')))))
            getPos(i,j) = 3;
        elseif (~isempty(data{i,2}(j).EVENTS.LABELS(find(contains(data{i,2}(j).EVENTS.LABELS,'STROOPC_YELLOW')))))
            getPos(i,j) = 4;
        else
            getPos(i,j) = 0;
        end
        
        if (~isempty((find(contains(data{i,2}(j).EVENTS.LABELS,'FALSE_START')))) || ~isempty((find(contains(data{i,2}(j).EVENTS.LABELS,'TIMED_OUT'))))) %if the trial is too early or didnt reach a target
            startTime(i,j) = nan; %time when trial begins
            stroopTime(i,j) = nan; %time when stroop target appears
            reactTime(i,j) = nan; %time when hand speed is > 10% of max hand speed
            trialResult(i,j) = nan; %correct or incorrect trial
            maxSpeed(i,j) = nan; %maximum hand speed
            maxDev(i,j) = nan;
            trialType(i,j) = nan; %congruent or incongruent trial
            reachTime(i,j) = nan; % time when the target was reached
            moveTime(i,j) = nan; %time between reaction time and reach time
        else
            findStart = find(contains(data{i,2}(j).EVENTS.LABELS,'TRIAL_START'));
            startTime(i,j) = round(data{i,2}(j).EVENTS.TIMES(findStart(end))*1000); %get start of trial time
            stroopTime(i,j) = round(data{i,2}(j).EVENTS.TIMES(find(contains(data{i,2}(j).EVENTS.LABELS,'CONGRUENT')))*1000); %get target appearance time (congruent or incongruent is found by this line)
            if (find(strcmp(data{i,2}(j).EVENTS.LABELS,'CONGRUENT')))
                trialType(i,j) = 0; %0 is congruent
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'INCONGRUENT')))
                trialType(i,j) = 1; %1 is incongruent
            else
                trialType(i,j) = nan;
            end
            if (find(strcmp(data{i,2}(j).EVENTS.LABELS,'CORRECT')))
                trialResult(i,j) = 1; %1 is correct
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'INCORRECT')))
                trialResult(i,j) = 0; %0 is incorrect
            else
                trialResult(i,j) = nan; %too slow
            end
            reachTime(i,j) = round(data{i,2}(j).EVENTS.TIMES(find(contains(data{i,2}(j).EVENTS.LABELS,'REACHED_T')))*1000); %reach event code starts with REACHED_T
            reactTime(i,j) = findReactTimePsych(dataAccel(stroopTime(i,j):reachTime(i,j)),i,j); %call on reaction time script
            maxSpeed(i,j) = max(dataSpeed)*100; %get highest hand speed and convert to cm/s
            maxDev(i,j) = findMaxAbDevPsych(dataXPos(stroopTime(i,j):reachTime(i,j)),dataYPos(stroopTime(i,j):reachTime(i,j)),getPos(i,j),data{1,2}(1).TARGET_TABLE,i,j); %get maximum hand deviation from a straight line to the target
        end

        %calc movement time
        moveTime(i,j) = reachTime(i,j)-reactTime(i,j)-stroopTime(i,j);
        
        %calc react time
        if (~isnan(reactTime(i,j)) || ~isnan(stroopTime(i,j)))
            reactTimeFull(i,j) = reactTime(i,j);
        else
            reactTimeFull(i,j) = nan;
        end
        
        %calc speed peaks
        %get speed peaks above posture speed
        if (~isnan(stroopTime(i,j)))
            dirChng(i,j) = findXFlipsPsych(dataXPos(stroopTime(i,j):reachTime(i,j)),dataYPos(stroopTime(i,j):reachTime(i,j)),...
                speedX(stroopTime(i,j):reachTime(i,j)),speedY(stroopTime(i,j):reachTime(i,j)),getPos(i,j),suiteNum,getPos(i,j),i,j);
        else
            dirChng(i,j) = nan;
        end
    end
end

% %nan the 0's as the blocked trials have 0's from 49-96 because they only
% %have 48 trials
% speedPeaks(speedPeaks == 0) = nan;
% moveTime(moveTime == 0) = nan;
% maxSpeed(maxSpeed == 0) = nan;
% reactTimeFull(reactTimeFull == 0) = nan;

%% pull out reaction time, movement time, distance ratio
%requires Statistics and Machine Learning Toolbox (matlab function corr)

%get average parameters for each trial type
for (i  = 1:size(data,1))
    %get parameters for the 50_50 static variant
    if (strcmp(data{i,3},'colourStroop50_50Static'))
        avgReact(i,1) = mean(reactTimeFull(i,(trialType(i,:) == 1)),'omitnan'); %incongruent
        avgReact(i,2) = mean(reactTimeFull(i,(trialType(i,:) == 0)),'omitnan'); %congruent
        avgMaxSpeed(i,1) = mean(maxSpeed(i,(trialType(i,:) == 1)),'omitnan');
        avgMaxSpeed(i,2) = mean(maxSpeed(i,(trialType(i,:) == 0)),'omitnan');
        avgMoveTime(i,1) = mean(moveTime(i,(trialType(i,:) == 1)),'omitnan');
        avgMoveTime(i,2) = mean(moveTime(i,(trialType(i,:) == 0)),'omitnan');
        avgPeaks(i,1) = mean(dirChng(i,(trialType(i,:) == 1)),'omitnan');
        avgPeaks(i,2) = mean(dirChng(i,(trialType(i,:) == 0)),'omitnan');
        avgMaxDev(i,1) = mean(maxDev(i,(trialType(i,:) == 1)),'omitnan');
        avgMaxDev(i,2) = mean(maxDev(i,(trialType(i,:) == 0)),'omitnan');
        array4corr{i,1} = [reactTimeFull(i,:);maxSpeed(i,:);moveTime(i,:);dirChng(i,:);maxDev(i,:);]; %combine parameters for heatmap later
    end
end

%organize array4corr to setup heatmap function
array4heat = [array4corr{1},array4corr{2},array4corr{3},array4corr{4},array4corr{5}];

%set the number of participants
for (i = 1:size(avgReact,1))
    stroopEffRT(i,1) = avgReact(i,2)-avgReact(i,1);
    stroopEffMS(i,1) = avgMaxSpeed(i,2)-avgMaxSpeed(i,1);
    stroopEffMT(i,1) = avgMoveTime(i,2)-avgMoveTime(i,1);
    stroopEffSP(i,1) = avgPeaks(i,2)-avgPeaks(i,1);
    stroopEffMD(i,1) = avgMaxDev(i,2)-avgMaxDev(i,1);
end

%participant average
stroopEffRT(i+1,:) = mean(stroopEffRT,'omitnan');
stroopEffMS(i+1,:) = mean(stroopEffMS,'omitnan');
stroopEffMT(i+1,:) = mean(stroopEffMT,'omitnan');
stroopEffSP(i+1,:) = mean(stroopEffSP,'omitnan');
stroopEffMD(i+1,:) = mean(stroopEffMD,'omitnan');

%generate comparison of parameters using a heat map 
corrLabels = [{'Reaction Time'};{'Max Speed'};{'Movement Time'};{'Speed Peaks'};{'Max Deviation'};];
for (k = 1)
    for (i = 1:size(corrLabels,1))
        for (j = 1:size(corrLabels,1))
            [corrArray{k}(i,j), pArray{k}(i,j)] = corr(array4heat(i,:)',array4heat(j,:)','Type','spearman','rows','complete');
            negArray{k}(i,j) = corrArray{k}(i,j)>0;
            corrArray{k}(i,j) = abs(round(corrArray{k}(i,j),2));
        end
    end
    figure,
    heatmap(corrLabels,corrLabels,corrArray{k})
    
end
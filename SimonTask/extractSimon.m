% run this script to extract parameters from the Flanker task
% assumes full dataset (all variants)
clearvars -except data loaded nameList excelName
close all

suiteNum = 2; 

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
        if (strcmp(data{i,2}(1).EXPERIMENT.ACTIVE_ARM,'RIGHT')) %check for right arm
            dataXPos = data{i,2}(j).Right_HandX; %xpos
            dataYPos = data{i,2}(j).Right_HandY; %ypos
            speedX = data{i,2}(j).Right_HandXVel;
            speedY = data{i,2}(j).Right_HandYVel;
            accelX = data{i,2}(j).Right_HandXAcc;
            jerkX = data{i,2}(j).Right_HandXJrk;
            dataSpeed = hypot(data{i,2}(j).Right_HandXVel,data{i,2}(j).Right_HandYVel); %hand speed
            dataAccel = hypot(data{i,2}(j).Right_HandXAcc,data{i,2}(j).Right_HandYAcc); %hand acceleration
            dataJerk = hypot(data{i,2}(j).Right_HandXJrk,data{i,2}(j).Right_HandYJrk); %hand jerk
        else %it is left arm
            dataXPos = data{i,2}(j).Left_HandX; %xpos
            dataYPos = data{i,2}(j).Left_HandY; %ypos
            speedX = data{i,2}(j).Left_HandXVel;
            speedY = data{i,2}(j).Left_HandYVel;
            accelX = data{i,2}(j).Left_HandXAcc;
            jerkX = data{i,2}(j).Left_HandXJrk;
            dataSpeed = hypot(data{i,2}(j).Left_HandXVel,data{i,2}(j).Left_HandYVel); %hand speed
            dataAccel = hypot(data{i,2}(j).Left_HandXAcc,data{i,2}(j).Left_HandYAcc); %hand acceleration
            dataJerk = hypot(data{i,2}(j).Left_HandXJrk,data{i,2}(j).Left_HandYJrk); %hand jerk
        end
        
        %get params
        if (~isempty((find(contains(data{i,2}(j).EVENTS.LABELS,'FALSE_START')))) || ~isempty((find(contains(data{i,2}(j).EVENTS.LABELS,'TIMED_OUT')))) || ~isempty((find(contains(data{i,2}(j).EVENTS.LABELS,'INCORRECT'))))) %if the trial is too early or didnt reach a target
            startTime(i,j) = nan; %time when trial begins
            simonTime(i,j) = nan; %time when simon appears
            reactTime(i,j) = nan; %time when hand speed is > 10% of max hand speed
            trialResult(i,j) = nan; %correct or incorrect trial
            maxSpeed(i,j) = nan; %maximum hand speed
            trialType(i,j) = nan; %congruent/incongruent/neutral trial
            reachTime(i,j) = nan; % time when the target was reached
            moveTime(i,j) = nan; %time between reaction time and reach time
            handJerk(i,j) = nan; %jerk in the x-direction
            oppDist(i,j) = nan;
        else
            %get time of trial simon appearance
            simonTime(i,j) = round(data{i,2}(j).EVENTS.TIMES(find(contains(data{i,2}(j).EVENTS.LABELS,'STIM_ON')))*1000); %get target appearance time (congruent or incongruent is found by this line)
            
            %get trial type
            if (find(strcmp(data{i,2}(j).EVENTS.LABELS,'CONGRUENT')))
                trialType(i,j) = 0; %0 is congruent
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'INCONGRUENT')))
                trialType(i,j) = 1; %1 is incongruent
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'NEUTRAL')))
                trialType(i,j) = 2; %2 is neutral
            else
                trialType(i,j) = nan;
            end

            %get stimulus location
            if (find(strcmp(data{i,2}(j).EVENTS.LABELS,'LOC_LSIDE'))) %left side
                stimLoc(i,j) = 1;
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'LOC_RSIDE'))) %right side
                stimLoc(i,j) = 2;
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'LOC_NEUT'))) %centre
                stimLoc(i,j) = 3;
            else
                stimLoc(i,j) = nan;
            end
            
            %get stimulus colour
            if (find(strcmp(data{i,2}(j).EVENTS.LABELS,'COL_LSTIM'))) %left movement stimulus
                stimCol(i,j) = 1;
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'COL_RSTIM'))) %right movement stimulus
                stimCol(i,j) = 2;
            else
                stimCol(i,j) = nan;
            end

            %get trial result
            if (find(strcmp(data{i,2}(j).EVENTS.LABELS,'CORRECT')))
                trialResult(i,j) = 1; %1 is correct
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'INCORRECT')))
                trialResult(i,j) = 0; %0 is incorrect
            else
                trialResult(i,j) = nan; %too slow
            end
            
            %get important times
            startTime(i,j) = round(data{i,2}(j).EVENTS.TIMES(find(contains(data{i,2}(j).EVENTS.LABELS,'WALLS_ON')))*1000); %get start of trial time
            reachTime(i,j) = round(data{i,2}(j).EVENTS.TIMES(find(contains(data{i,2}(j).EVENTS.LABELS,'_REACHED')))*1000); %reach event code starts with REACHED_T
            reactTime(i,j) = findReactTimePsych(dataAccel(simonTime(i,j):reachTime(i,j)),i,j); %call on reaction time script
            if (stimCol(i,j) == 1) %flip speed to make left movements positive
                maxSpeed(i,j) = max(-speedX(simonTime(i,j):end))*100; %hand speed
            else
                maxSpeed(i,j) = max(speedX(simonTime(i,j):end))*100; %hand speed
            end
            oppDist(i,j) = findOppDistPsych(dataXPos(simonTime(i,j):reachTime(i,j)),stimCol(i,j),i,j); %call on function to get the opposite distance
        end

        %calc speed peaks
        %get speed peaks above posture speed
        if (~isnan(simonTime(i,j)))
            dirChng(i,j) = findXFlipsPsych(dataXPos(simonTime(i,j):reachTime(i,j)),dataYPos(simonTime(i,j):reachTime(i,j)),...
                speedX(simonTime(i,j):reachTime(i,j)),speedY(simonTime(i,j):reachTime(i,j)),stimCol(i,j),suiteNum,stimCol(i,j),i,j);
        else
            dirChng(i,j) = nan;
        end

        %calc movement time
        moveTime(i,j) = reachTime(i,j)-reactTime(i,j)-simonTime(i,j);
        
        %calc react time
        if (~isnan(reactTime(i,j)) || ~isnan(simonTime(i,j)))
            reactTimeFull(i,j) = reactTime(i,j);
        else
            reactTimeFull(i,j) = nan;
        end
    end
end

%% pull out params for different task features (cue types, trial type)
%initialize counter
base = 1;

for (i  = 1:size(data,1))
    %get parameters for the simon
    if (strcmp(data{i,3},'baseSimon'))
        avgReact(base,1) = mean(reactTimeFull(i,(trialType(i,:) == 1)),'omitnan'); %1 = incongruent
        avgReact(base,2) = mean(reactTimeFull(i,(trialType(i,:) == 0)),'omitnan'); %0 = congruent
        avgReact(base,3) = mean(reactTimeFull(i,(trialType(i,:) == 2)),'omitnan'); %2 = neutral
        avgMaxSpeed(base,1) = mean(maxSpeed(i,(trialType(i,:) == 1)),'omitnan');
        avgMaxSpeed(base,2) = mean(maxSpeed(i,(trialType(i,:) == 0)),'omitnan');
        avgMaxSpeed(base,3) = mean(maxSpeed(i,(trialType(i,:) == 2)),'omitnan');
        avgMoveTime(base,1) = mean(moveTime(i,(trialType(i,:) == 1)),'omitnan');
        avgMoveTime(base,2) = mean(moveTime(i,(trialType(i,:) == 0)),'omitnan');
        avgMoveTime(base,3) = mean(moveTime(i,(trialType(i,:) == 2)),'omitnan');
        avgDirChng(base,1) = mean(dirChng(i,(trialType(i,:) == 1)),'omitnan');
        avgDirChng(base,2) = mean(dirChng(i,(trialType(i,:) == 0)),'omitnan');
        avgDirChng(base,3) = mean(dirChng(i,(trialType(i,:) == 2)),'omitnan');
        avgOppDist(base,1) = mean(oppDist(i,(trialType(i,:) == 1)),'omitnan');
        avgOppDist(base,2) = mean(oppDist(i,(trialType(i,:) == 0)),'omitnan');
        avgOppDist(base,3) = mean(oppDist(i,(trialType(i,:) == 2)),'omitnan');
        array4base{base,1} = [reactTimeFull(i,:);maxSpeed(i,:);moveTime(i,:);dirChng(i,:);oppDist(i,:);]; %organize parameters for heatmap later
        base = base + 1;
    end
end

%organize array to setup heatmap function
%requires Statistics and Machine Learning Toolbox (matlab function corr)
array4heat{1} = [array4base{1,1},array4base{2,1}];

%set the number of participants
for (i = 1:size(avgReact,1))
    avgRT(i,1) = avgReact(i,2)-avgReact(i,1); %get simon effect for rt
    avgMS(i,1) = avgMaxSpeed(i,2)-avgMaxSpeed(i,1); %get simon effect for max speed
    avgMT(i,1) = avgMoveTime(i,2)-avgMoveTime(i,1); %get simon effect for movement time
    avgDC(i,1) = avgDirChng(i,2)-avgDirChng(i,1); %get simon effect for speed peaks
    avgOD(i,1) = avgOppDist(i,2)-avgOppDist(i,1); %get simon effect for opposite distance
end

%participant average
avgRT(i+1,:) = mean(avgRT(:,1),'omitnan');
avgMS(i+1,:) = mean(avgMS(:,1),'omitnan');
avgMT(i+1,:) = mean(avgMT(:,1),'omitnan');
avgDC(i+1,:) = mean(avgDC(:,1),'omitnan');
avgOD(i+1,:) = mean(avgOD(:,1),'omitnan');

%generate comparison between parameters using a heatmap
corrLabels = [{'Reaction Time'};{'Max Speed'};{'Move Time'};{'Direction Change'};{'Opposite Distance'}];
for (k = 1)
    for (i = 1:size(corrLabels,1))
        for (j = 1:size(corrLabels,1))
            [corrArray{k}(i,j), pArray{k}(i,j)] = corr(array4heat{k}(i,:)',array4heat{k}(j,:)','Type','spearman','rows','complete');
            negArray{k}(i,j) = corrArray{k}(i,j)>0;
            corrArray{k}(i,j) = abs(round(corrArray{k}(i,j),2));
        end
    end
    figure,
    heatmap(corrLabels,corrLabels,corrArray{k})
end
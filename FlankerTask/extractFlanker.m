% run this script to extract parameters from the Flanker task
% assumes full dataset (all variants)
clearvars -except data loaded nameList excelName
close all

suiteNum = 1;

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
            dataSpeed = hypot(data{i,2}(j).Right_HandXVel,data{i,2}(j).Right_HandYVel); %hand speed
            dataAccel = hypot(data{i,2}(j).Right_HandXAcc,data{i,2}(j).Right_HandYAcc); %hand acceleration
        else %it is left arm
            dataXPos = data{i,2}(j).Left_HandX; %xpos
            dataYPos = data{i,2}(j).Left_HandY; %ypos
            speedX = data{i,2}(j).Left_HandXVel;
            speedY = data{i,2}(j).Left_HandYVel;
            dataSpeed = hypot(data{i,2}(j).Left_HandXVel,data{i,2}(j).Left_HandYVel); %hand speed
            dataAccel = hypot(data{i,2}(j).Left_HandXAcc,data{i,2}(j).Left_HandYAcc); %hand acceleration
        end
        
        %get params
        if (~isempty((find(contains(data{i,2}(j).EVENTS.LABELS,'FALSE_START')))) || ~isempty((find(contains(data{i,2}(j).EVENTS.LABELS,'TIMED_OUT'))))) %if the trial is too early or didnt reach a target
            startTime(i,j) = nan; %time when trial begins
            flankTime(i,j) = nan; %time when flanker appears
            cueTime(i,j) = nan; %time when cue turned on
            cueType(i,j) = nan; %type of cue that turned on
            arrowPos(i,j) = nan; %arrow position on top or bottom
            centreDir(i,j) = nan; %centre arrow direction
            distrDir(i,j) = nan; %distractor arrow direction
            reactTime(i,j) = nan; %time when hand speed is > 10% of max hand speed
            trialResult(i,j) = nan; %correct or incorrect trial
            maxSpeed(i,j) = nan; %maximum hand speed
            trialType(i,j) = nan; %congruent/incongruent/neutral trial
            reachTime(i,j) = nan; % time when the target was reached
            moveTime(i,j) = nan; %time between reaction time and reach time
            oppDist(i,j) = nan;
        else
            %get time of trial flank appearance
            if (find(contains(data{i,2}(j).EVENTS.LABELS,'CONGRUENT')))
                flankTime(i,j) = round(data{i,2}(j).EVENTS.TIMES(find(contains(data{i,2}(j).EVENTS.LABELS,'CONGRUENT')))*1000); %get target appearance time (congruent or incongruent is found by this line)
            elseif (find(contains(data{i,2}(j).EVENTS.LABELS,'NEUTRAL')))
                flankTime(i,j) = round(data{i,2}(j).EVENTS.TIMES(find(contains(data{i,2}(j).EVENTS.LABELS,'NEUTRAL')))*1000);
            end
            
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

            %get centre arrow direction
            if (find(strcmp(data{i,2}(j).EVENTS.LABELS,'CENTRE_LEFT')))
                centreDir(i,j) = 1;
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'CENTRE_RIGHT')))
                centreDir(i,j) = 2;
            else
                centreDir(i,j) = nan;
            end
            
            %get distractor arrow direction
            if (find(strcmp(data{i,2}(j).EVENTS.LABELS,'DISTRACT_LEFT')))
                distrDir(i,j) = 1;
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'DISTRACT_RIGHT')))
                distrDir(i,j) = 2;
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'DISTRACT_NEUT')))
                distrDir(i,j) = 3;
            else
                distrDir(i,j) = nan;
            end
            
            %get position of arrows
            if (find(strcmp(data{i,2}(j).EVENTS.LABELS,'ARROWS_TOP')))
                arrowPos(i,j) = 1;
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'ARROWS_BOT')))
                arrowPos(i,j) = 2;
            else
                arrowPos(i,j) = nan;
            end

            %get cue type and time
            if (find(strcmp(data{i,2}(j).EVENTS.LABELS,'CUE_NONE')))
                cueType(i,j) = 0;%no cue
                cueTime(i,j) = round(data{i,2}(j).EVENTS.TIMES(find(contains(data{i,2}(j).EVENTS.LABELS,'CUE_NONE')))*1000);
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'CUE_TOP')))
                cueType(i,j) = 1; %cue above start target
                cueTime(i,j) = round(data{i,2}(j).EVENTS.TIMES(find(contains(data{i,2}(j).EVENTS.LABELS,'CUE_TOP')))*1000);
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'CUE_BOT')))
                cueType(i,j) = 2; %cue below start target
                cueTime(i,j) = round(data{i,2}(j).EVENTS.TIMES(find(contains(data{i,2}(j).EVENTS.LABELS,'CUE_BOT')))*1000);
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'CUE_BOTH')))
                cueType(i,j) = 3; %cue above and below start target
                cueTime(i,j) = round(data{i,2}(j).EVENTS.TIMES(find(contains(data{i,2}(j).EVENTS.LABELS,'CUE_BOTH')))*1000);
            elseif (find(strcmp(data{i,2}(j).EVENTS.LABELS,'CUE_CENTRE')))
                cueType(i,j) = 4; %cue in at the start target (hand cursor switches to cue)
                cueTime(i,j) = round(data{i,2}(j).EVENTS.TIMES(find(contains(data{i,2}(j).EVENTS.LABELS,'CUE_CENTRE')))*1000);
            else
                cueType(i,j) = nan;
                cueTime(i,j) = nan;
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
            reachTime(i,j) = round(data{i,2}(j).EVENTS.TIMES(find(contains(data{i,2}(j).EVENTS.LABELS,'_REACHED')))*1000); %reach time
            reactTime(i,j) = findReactTimePsych(dataAccel(flankTime(i,j):reachTime(i,j)),i,j); %call on reaction time script
            if (centreDir(i,j) == 1) %flip speed to make left movements positive
                maxSpeed(i,j) = max(-speedX(flankTime(i,j):end))*100; %hand speed
            else
                maxSpeed(i,j) = max(speedX(flankTime(i,j):end))*100; %hand speed
            end
            oppDist(i,j) = findOppDistPsych(dataXPos(flankTime(i,j):reachTime(i,j)),centreDir(i,j),i,j); 
        end

        %calc direction changes
        %get speed peaks above posture speed
        if (~isnan(flankTime(i,j)))
            dirChng(i,j) = findXFlipsPsych(dataXPos(flankTime(i,j):reachTime(i,j)),dataYPos(flankTime(i,j):reachTime(i,j)),...
                speedX(flankTime(i,j):reachTime(i,j)),speedY(flankTime(i,j):reachTime(i,j)),centreDir(i,j),suiteNum,centreDir(i,j),i,j);
        else
            dirChng(i,j) = nan;
        end

        %calc movement time
        moveTime(i,j) = reachTime(i,j)-reactTime(i,j)-flankTime(i,j);
        
        %calc react time
        if (~isnan(reactTime(i,j)) || ~isnan(flankTime(i,j)))
            reactTimeFull(i,j) = reactTime(i,j);
        else
            reactTimeFull(i,j) = nan;
        end
    end
end

%% pull out params for different task features (cue types, trial type)

%initialize counters for different variants
exec = 1;
alert = 1;
ori = 1;
base = 1;

for (i  = 1:size(data,1)) %for each person
    %get parameters for the ANT executive control (incongruent-congruent)
    if (strcmp(data{i,3},'ANT'))
        execReact(exec,1) = mean(reactTimeFull(i,(trialType(i,:) == 0)),'omitnan'); %get average RT for congruent trials
        execReact(exec,2) = mean(reactTimeFull(i,(trialType(i,:) == 1)),'omitnan'); %get average RT for incongruent trials
        execMaxSpeed(exec,1) = mean(maxSpeed(i,(trialType(i,:) == 0)),'omitnan');
        execMaxSpeed(exec,2) = mean(maxSpeed(i,(trialType(i,:) == 1)),'omitnan');
        execMoveTime(exec,1) = mean(moveTime(i,(trialType(i,:) == 0)),'omitnan');
        execMoveTime(exec,2) = mean(moveTime(i,(trialType(i,:) == 1)),'omitnan');
        execDirChng(exec,1) = mean(dirChng(i,(trialType(i,:) == 0)),'omitnan');
        execDirChng(exec,2) = mean(dirChng(i,(trialType(i,:) == 1)),'omitnan');
        execOppDist(exec,1) = mean(oppDist(i,(trialType(i,:) == 0)),'omitnan');
        execOppDist(exec,2) = mean(oppDist(i,(trialType(i,:) == 1)),'omitnan');
        array4ant{exec,1} = [reactTimeFull(i,:);maxSpeed(i,:);moveTime(i,:);dirChng(i,:);oppDist(i,:);]; %get arrays for comparing within task parameter correlations
        exec = exec + 1;
    end
    %get parameters for the ANT alert (nocue-doublecue)
    if (strcmp(data{i,3},'ANT'))
        alertReact(alert,1) = mean(reactTimeFull(i,(cueType(i,:) == 3)),'omitnan'); %get average RT for top and bottom cue
        alertReact(alert,2) = mean(reactTimeFull(i,(cueType(i,:) == 0)),'omitnan'); %get average RT for no cue
        alertMaxSpeed(alert,1) = mean(maxSpeed(i,(cueType(i,:) == 3)),'omitnan');
        alertMaxSpeed(alert,2) = mean(maxSpeed(i,(cueType(i,:) == 0)),'omitnan');
        alertMoveTime(alert,1) = mean(moveTime(i,(cueType(i,:) == 3)),'omitnan');
        alertMoveTime(alert,2) = mean(moveTime(i,(cueType(i,:) == 0)),'omitnan');
        alertDirChng(alert,1) = mean(dirChng(i,(cueType(i,:) == 3)),'omitnan');
        alertDirChng(alert,2) = mean(dirChng(i,(cueType(i,:) == 0)),'omitnan');
        alertOppDist(alert,1) = mean(oppDist(i,(cueType(i,:) == 3)),'omitnan');
        alertOppDist(alert,2) = mean(oppDist(i,(cueType(i,:) == 0)),'omitnan');
        alert = alert + 1;
    end
    %get parameters for the ANT orient (centrecue-spatialcue)
    if (strcmp(data{i,3},'ANT'))
        oriReact(ori,1) = mean([reactTimeFull(i,(cueType(i,:) == 1)),reactTimeFull(i,(cueType(i,:) == 2))],'omitnan'); %get average RT for top or bottom cue
        oriReact(ori,2) = mean(reactTimeFull(i,(cueType(i,:) == 4)),'omitnan'); %get average RT for centre cue
        oriMaxSpeed(ori,1) = mean([maxSpeed(i,(cueType(i,:) == 1)),maxSpeed(i,(cueType(i,:) == 2))],'omitnan');
        oriMaxSpeed(ori,2) = mean(maxSpeed(i,(cueType(i,:) == 4)),'omitnan');
        oriMoveTime(ori,1) = mean([moveTime(i,(cueType(i,:) == 1)),moveTime(i,(cueType(i,:) == 2))],'omitnan');
        oriMoveTime(ori,2) = mean(moveTime(i,(cueType(i,:) == 4)),'omitnan');
        oriDirChng(ori,1) = mean([dirChng(i,(cueType(i,:) == 1)),dirChng(i,(cueType(i,:) == 2))],'omitnan');
        oriDirChng(ori,2) = mean(dirChng(i,(cueType(i,:) == 4)),'omitnan');
        oriOppDist(ori,1) = mean([oppDist(i,(cueType(i,:) == 1)),oppDist(i,(cueType(i,:) == 2))],'omitnan');
        oriOppDist(ori,2) = mean(oppDist(i,(cueType(i,:) == 4)),'omitnan');
        ori = ori + 1;
    end

    %get parameters for the base flanker
    if (strcmp(data{i,3},'baseFlanker'))
        avgReact(base,1) = mean(reactTimeFull(i,(trialType(i,:) == 1)),'omitnan'); %incongruent trials
        avgReact(base,2) = mean(reactTimeFull(i,(trialType(i,:) == 0)),'omitnan'); %congruent trials
        avgReact(base,3) = mean(reactTimeFull(i,(trialType(i,:) == 2)),'omitnan'); %neutral trials
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
        array4base{base,1} = [reactTimeFull(i,:);maxSpeed(i,:);moveTime(i,:);dirChng(i,:);oppDist(i,:);];
        base = base + 1;
    end
end

%organize array4corr to setup heatmap function
%requires Statistics and Machine Learning Toolbox (matlab function corr)

%array4heat{1} = [array4ant{1,1}]; %commented out analysis for ANT 
array4heat = [array4base{1,1},array4base{2,1},array4base{3,1};];

% set the number of participants
for (i = 1:size(avgReact,1))
    % execRT(i,1) = execReact(i,2)-execReact(i,1);
    % execMS(i,1) = execMaxSpeed(i,2)-execMaxSpeed(i,1);
    % execMT(i,1) = execMoveTime(i,2)-execMoveTime(i,1);
    % execSP(i,1) = execPeaks(i,2)-execPeaks(i,1);
    % execOD(i,1) = execOppDist(i,2)-execOppDist(i,1);
    % 
    % alertRT(i,1) = alertReact(i,2)-alertReact(i,1);
    % alertMS(i,1) = alertMaxSpeed(i,2)-alertMaxSpeed(i,1);
    % alertMT(i,1) = alertMoveTime(i,2)-alertMoveTime(i,1);
    % alertSP(i,1) = alertPeaks(i,2)-alertPeaks(i,1);
    % alertOD(i,1) = alertOppDist(i,2)-alertOppDist(i,1);
    % 
    % oriRT(i,1) = oriReact(i,2)-oriReact(i,1);
    % oriMS(i,1) = oriMaxSpeed(i,2)-oriMaxSpeed(i,1);
    % oriMT(i,1) = oriMoveTime(i,2)-oriMoveTime(i,1);
    % oriSP(i,1) = oriPeaks(i,2)-oriPeaks(i,1);
    % oriOD(i,1) = oriOppDist(i,2)-oriOppDist(i,1);

    avgRT(i,1) = avgReact(i,2)-avgReact(i,1); %flanker effect
    avgMS(i,1) = avgMaxSpeed(i,2)-avgMaxSpeed(i,1); %flanker effect for max speed
    avgMT(i,1) = avgMoveTime(i,2)-avgMoveTime(i,1); %flanker effect for movement time
    avgDC(i,1) = avgDirChng(i,2)-avgDirChng(i,1); %flanker effect for speed peaks
    avgOD(i,1) = avgOppDist(i,2)-avgOppDist(i,1); %flanker effect for opposite distance
end

% execRT(i+1,:) = mean(execRT(:,1),'omitnan');
% execMS(i+1,:) = mean(execMS(:,1),'omitnan');
% execMT(i+1,:) = mean(execMT(:,1),'omitnan');
% execSP(i+1,:) = mean(execSP(:,1),'omitnan');
% execOD(i+1,:) = mean(execOD(:,1),'omitnan');
% 
% alertRT(i+1,:) = mean(alertRT(:,1),'omitnan');
% alertMS(i+1,:) = mean(alertMS(:,1),'omitnan');
% alertMT(i+1,:) = mean(alertMT(:,1),'omitnan');
% alertSP(i+1,:) = mean(alertSP(:,1),'omitnan');
% alertOD(i+1,:) = mean(alertOD(:,1),'omitnan');
% 
% oriRT(i+1,:) = mean(oriRT(:,1),'omitnan');
% oriMS(i+1,:) = mean(oriMS(:,1),'omitnan');
% oriMT(i+1,:) = mean(oriMT(:,1),'omitnan');
% oriSP(i+1,:) = mean(oriSP(:,1),'omitnan');
% oriOD(i+1,:) = mean(oriOD(:,1),'omitnan');

%get average for each participant
avgRT(i+1,:) = mean(avgRT(:,1),'omitnan');
avgMS(i+1,:) = mean(avgMS(:,1),'omitnan');
avgMT(i+1,:) = mean(avgMT(:,1),'omitnan');
avgDC(i+1,:) = mean(avgDC(:,1),'omitnan');
avgOD(i+1,:) = mean(avgOD(:,1),'omitnan');

%get heatmap to compare parameters
corrLabels = [{'Reaction Time'};{'Max Speed'};{'Move Time'};{'Direction Change'};{'Opposite Distance'}];
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
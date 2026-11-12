% run this script to extract parameters from the Kinarm unimanual approach avoidance task
% assumes full dataset (all variants)
clearvars -except data loaded nameList excelName
close all

suiteNum = 4;
plotPathSpeed = 0; %set to 1 for data of exemplars path, 2 is exemplar speed
%% load in data
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

%% get image and trial number association
%active
imageArray{1} = 'ap-cour';
imageArray{2} = 'ap-escal';
imageArray{3} = 'ap-foot';
imageArray{4} = 'ap-nat';
imageArray{5} = 'ap-rando';
imageArray{6} = 'ap-vel';

%sedentary
imageArray{7} = 'sed-canap';
imageArray{8} = 'sed-hamac';
imageArray{9} = 'sed-jvid';
imageArray{10} = 'sed-lect';
imageArray{11} = 'sed-ordi';
imageArray{12} = 'sed-tv';

%circle
imageArray{13} = 'ap-natr';
imageArray{14} = 'ap-randor';
imageArray{15} = 'ap-velr';
imageArray{16} = 'sed-canapr';
imageArray{17} = 'sed-hamacr';
imageArray{18} = 'sed-lectr';

%square
imageArray{19} = 'ap-natc';
imageArray{20} = 'ap-randoc';
imageArray{21} = 'ap-velc';
imageArray{22} = 'sed-canapc';
imageArray{23} = 'sed-hamacc';
imageArray{24} = 'sed-lectc';
    
%% initialize
%% find length of blocks

% i = 2;
wrongDir = zeros(1,1);
errorCount = 1;
lostCount = 1;
for (i = 1:size(data,1))
    dataRun{i} = data{i,2};
    partInfo{i} = struct('ID',[],'Sex',[],'Handedness',[],'BlockType',[],'ReachLocation',[],'TrialType',[],'ImageName',[],'AppAvoid',[],...
        'TrialResult',[],'MovementTime',[],'MaxSpeed',[],'OppDist',[],'ReactionTime',[], 'DirectChange',[]);
        
    blockCount = 1;
    for (j = 1:size(dataRun{i},2))
        if (find(contains(dataRun{i}(j).EVENTS.LABELS,'BLOCK_')))
            blockStart(blockCount) = j;
            blockCount = blockCount + 1;
        elseif (find(contains(dataRun{i}(j).EVENTS.LABELS,'_APP')))
            blockStart(blockCount) = j;
            findBlock = extractBefore(dataRun{i}(j).EVENTS.LABELS(1),'_APP');
            blockCount = blockCount + 1;
        end
    end
    
    blockArray{1} = (blockStart(1):blockStart(2)-1);
    blockArray{2} = (blockStart(2):blockStart(3)-1);
    blockArray{3} = (blockStart(3):blockStart(4)-1);
    blockArray{4} = (blockStart(4):length(dataRun{i}));
    blockError = cell(1,4);

    %% start processing
    for (z = 1:4)
        blockCond{z} = extractBefore(dataRun{i}(blockArray{z}(1)).EVENTS.LABELS(1),'_APP');
        if (plotPathSpeed > 0) %if plotting make a new figure for each trial block
            a = figure,
        end
        for (j = blockArray{z}) %go through each trial in each block
            %% get data from hand that was tested
            if (find(contains(dataRun{i}(1).EXPERIMENT.ARM_TO_BE_ASSESSED,'LEFT')))
                dataXPos = dataRun{i}(j).Left_HandX; %xpos
                dataYPos = dataRun{i}(j).Left_HandY; %ypos
                dataXSpeed = dataRun{i}(j).Left_HandXVel;
                dataYSpeed = dataRun{i}(j).Left_HandYVel;
                dataSpeed = hypot(dataRun{i}(j).Left_HandXVel,dataRun{i}(j).Left_HandYVel); %hand speed
                dataAccel = hypot(dataRun{i}(j).Left_HandXAcc,dataRun{i}(j).Left_HandYAcc); %hand acceleration
            else
                dataXPos = dataRun{i}(j).Right_HandX;
                dataYPos = dataRun{i}(j).Right_HandY;
                dataXSpeed = dataRun{i}(j).Right_HandXVel;
                dataYSpeed = dataRun{i}(j).Right_HandYVel;
                dataSpeed = hypot(dataRun{i}(j).Right_HandXVel,dataRun{i}(j).Right_HandYVel);
                dataAccel = hypot(dataRun{i}(j).Right_HandXAcc,dataRun{i}(j).Right_HandYAcc);
            end

            %% get important trial times
            if (isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'TIMED_OUT')))) %if the trial is not timed out
                if (length(find(contains(dataRun{i}(j).EVENTS.LABELS,'HAND_IN_START')))>1) %check if person was unable to hold in start
                    startArray = find(contains(dataRun{i}(j).EVENTS.LABELS,'HAND_IN_START'));
                    startIndex = startArray(end);
                else
                    startIndex = find(contains(dataRun{i}(j).EVENTS.LABELS,'HAND_IN_START'));
                end
                trialStartTime(j) = round(dataRun{i}(j).EVENTS.TIMES(startIndex)*1000); %get start of trial time
                targetOnTime(j) = round(dataRun{i}(j).EVENTS.TIMES(find(contains(dataRun{i}(j).EVENTS.LABELS,'LOCATION_')))*1000); %get target appearance time
                if (~isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'APPROACHED')))) %get index if approached target
                    endIndex = find(contains(dataRun{i}(j).EVENTS.LABELS,'APPROACHED'));
                elseif (~isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'AVOIDED')))) %get index if avoided target
                    endIndex = find(contains(dataRun{i}(j).EVENTS.LABELS,'AVOIDED'));
                elseif (~isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'ERROR_TRIAL')))) %get index if they made an error
                    endIndex = find(contains(dataRun{i}(j).EVENTS.LABELS,'ERROR_TRIAL'));
                end
                trialEndTime(j) = round(dataRun{i}(j).EVENTS.TIMES(endIndex)*1000); %time of approach/avoid/error
            else %empty the value if there was a time out
                trialStartTime(j) = nan;
                targetOnTime(j) = nan;
                trialEndTime(j) = nan;
            end

            %% record the trials that were errors
            if (~isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'ERROR_TRIAL'))))
                blockError{z}(errorCount) = j;
                errorCount = errorCount + 1;
            end

            %% get sex
            if (strcmpi(dataRun{i}(1).EXPERIMENT.SUBJECT_SEX,'f'))
                partSex{j} = 'FEMALE';
            else
                partSex{j} = 'MALE';
            end

            %% get handedness
            if (strcmpi(dataRun{i}(1).EXPERIMENT.SUBJECT_HANDEDNESS,'right'))
                partHand{j} = 'RIGHT HANDED';
            else
                partHand{j} = 'LEFT HANDED';
            end

            %% get trial specific parameters

            reachCond1{j} = blockCond{z}; %get block condition

            if (dataRun{i}(j).TRIAL.TP < 7) %see if trial was active condition
                trialCond{j} = 'COND1'; 
                trialType(j) = 0;
            elseif (dataRun{i}(j).TRIAL.TP > 6 && dataRun{i}(j).TRIAL.TP < 13) %see if trial was sedentary
                trialCond{j} = 'COND2';
                trialType(j) = 1;
            elseif (dataRun{i}(j).TRIAL.TP > 12 && dataRun{i}(j).TRIAL.TP < 19) %see if trial was circle
                trialCond{j} = 'NEUT1';
                trialType(j) = 2;
            else %see if trial was square
                trialCond{j} = 'NEUT2';
                trialType(j) = 3;
            end

            reachTrialNum{j} = dataRun{i}(j).TRIAL.TRIAL_NUM; %get trial number
            reachImage{j} = imageArray{dataRun{i}(j).TRIAL.TP}; %get image name

            if (isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'TIMED_OUT')))) %for non timed out trials

                whereLoc = (find(contains(dataRun{i}(j).EVENTS.LABELS,'LOCATION_')));
                whatLoc = (extractAfter(dataRun{i}(j).EVENTS.LABELS(whereLoc),'_'));
                reachLoc(j) = str2num(whatLoc{1}); %get reach location
                
                approached = (find(contains(dataRun{i}(j).EVENTS.LABELS,'APPROACHED'))>0);
                avoided = (find(contains(dataRun{i}(j).EVENTS.LABELS,'AVOIDED'))>0);
                if (~isempty(approached) || ~isempty(avoided))
                    if (approached)
                        appAvoid(j) = 0;
                        appAvoidText{j} = 'APPROACHED';
                    end
                    if (avoided)
                        appAvoid(j) = 1;
                        appAvoidText{j} = 'AVOIDED';
                    end
                else
                    appAvoid(j) = 2;
                    appAvoidText{j} = 'INCORRECT';
                end

                if (~isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'ERROR_TRIAL')))) %check if error trial
                    reachERR{j} = 'ERROR';
                else
                    reachERR{j} = 'SUCCESS';
                end

                reachTO{j} = 'REACH MADE'; %not timed out

            else

                if (~isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'LOCATION_'))))
                    whereLoc = (find(contains(dataRun{i}(j).EVENTS.LABELS,'LOCATION_')));
                    whatLoc = (extractAfter(dataRun{i}(j).EVENTS.LABELS(whereLoc),'_'));
                    reachLoc(j) = str2num(whatLoc{1}); % get reach location
                else
                    reachLoc(j) = nan;
                end
                
                appAvoid(j) = nan;
                appAvoidText{j} = 'TIMED OUT';

                reachERR{j} = 'TIMED OUT'; %no error can be made just timed out

                reachTO{j} = 'TIMED OUT'; %timed out
            end

            %% get variables dependent on times
            
            if (strcmpi(reachTO{j},'TIMED OUT'))
                startDelay(j) = nan;
                moveTime(i,j) = nan;
                maxSpeed(i,j) = nan;
                reactTime(i,j) = nan;
                oppDist(i,j) = nan;
                initDir(j) = nan;
                dirChng(i,j) = nan;
            else
                startDelay(j) = targetOnTime(j) - trialStartTime(j); %get start delay
                accelPos(i,j) = mean(dataAccel(targetOnTime(j)-250:targetOnTime(j)));
                reactTime(i,j) = findReactTimePsych(dataAccel(targetOnTime(j):trialEndTime(j)),i,j,accelPos(i,j)); %call on reaction time script
                % reactTime2(i,j) = findReactTimePsych(dataAccel(targetOnTime(j):trialEndTime(j)),i,j,0); %call on reaction time script
                if (~isnan(reactTime(i,j)))
                    moveTime(i,j) = trialEndTime(j) - targetOnTime(j) - reactTime(i,j); %get movement time
                    maxSpeed(i,j) = findMaxSpeed(dataSpeed(targetOnTime(j):(trialEndTime(j)))); %get max speed
                    oppDist(i,j) = findOppDistAAT(dataXPos(targetOnTime(j):trialEndTime(j)),dataYPos(targetOnTime(j):trialEndTime(j)),reachLoc(j),appAvoid(j),i,j); %call on function to get the opposite distance
                    initDir(j) = findInitDir(dataXPos(targetOnTime(j):trialEndTime(j)),dataYPos(targetOnTime(j):trialEndTime(j)),dataSpeed(targetOnTime(j):trialEndTime(j)),reachLoc(j),appAvoid(j),i,j); %get the angle of the initial movement
                    dirChng(i,j) = findXFlipsPsych(dataXPos(targetOnTime(j):trialEndTime(j)),dataYPos(targetOnTime(j):trialEndTime(j)),dataXSpeed(targetOnTime(j):trialEndTime(j)),dataYSpeed(targetOnTime(j):trialEndTime(j)),reachLoc(j),suiteNum,appAvoid(j),i,j);
                else
                    moveTime(i,j) = nan;
                    maxSpeed(i,j) = nan;
                    oppDist(i,j) = nan;
                    initDir(j) = nan;
                    dirChng(i,j) = nan;
                end
            end

            %% make struct and output excel file
            nameList{i} = data{i,1}{1}(1:9);
            partInfo{i}(j).ID = nameList{i};
            partInfo{i}(j).Sex = partSex{i};
            partInfo{i}(j).Handedness = partHand{i};
            partInfo{i}(j).BlockType = reachCond1{j};
            partInfo{i}(j).ReachLocation = reachLoc(j);
            partInfo{i}(j).TrialType = trialCond{j};
            partInfo{i}(j).ImageName = reachImage{j};
            partInfo{i}(j).AppAvoid = appAvoidText{j};
            partInfo{i}(j).TrialResult = reachERR{j};
            partInfo{i}(j).MovementTime = moveTime(i,j);
            partInfo{i}(j).MaxSpeed = maxSpeed(i,j);
            partInfo{i}(j).OppDist = oppDist(i,j);
            partInfo{i}(j).ReactionTime = reactTime(i,j);
            partInfo{i}(j).InitDir = initDir(j);

            %% plot left and right arms
            if (plotPathSpeed == 1)
                typePlot = 'Path';
                if (strcmpi(blockCond{z},trialCond{j})) %if trial type is same as block type, assumes this block and trial is approach
                    subplot(2,2,1)
                    hold on
                    if (~isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'APPROACHED')))) %check if correctly approached
                        plot(dataXPos,dataYPos,'color','b');
                    elseif (~isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'TIMED_OUT'))))
                        plot(dataXPos,dataYPos,'color','r');
                        lostTrial(lostCount) = j;
                        lostCount = lostCount + 1;
                    else %error trial
                        plot(dataXPos,dataYPos,'color','r');
                        lostTrial(lostCount) = j;
                        lostCount = lostCount + 1;
                    end
                    title(['Hand Paths ' blockCond{z} ' Approach']);
                    ylabel('Y (m)');
                    xlabel('X (m)');
                else %plot the avoid condition for the other type of stimulus
                    subplot(2,2,3)
                    hold on
                    if (~isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'AVOIDED')))) %check if correctly avoided
                        plot(dataXPos,dataYPos,'color','b');
                    elseif (~isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'TIMED_OUT'))))
                        plot(dataXPos,dataYPos,'color','r');
                        lostTrial(lostCount) = j;
                        lostCount = lostCount + 1;
                    else %error trial
                        plot(dataXPos,dataYPos,'color','r');
                        lostTrial(lostCount) = j;
                        lostCount = lostCount + 1;
                    end
                    title(['Avoid']);
                end
            elseif (plotPathSpeed == 2)
                typePlot = 'Speed';
                if (strcmpi(blockCond{z},trialCond{j})) %if trial type is same as block type, assumes this block and trial is approach
                    subplot(2,2,1)
                    hold on
                    if (~isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'APPROACHED')))) %check if correctly approached
                        plot((0:length(dataSpeed)-targetOnTime(j)),dataSpeed(targetOnTime(j):end),'color','b');
                    elseif (~isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'TIMED_OUT'))))
                        if (~isnan(targetOnTime(j)))
                            plot((0:length(dataSpeed)-targetOnTime(j)),dataSpeed(targetOnTime(j):end),'color','r');
                        end
                        lostTrial(lostCount) = j;
                        lostCount = lostCount + 1;
                    else %error trial
                        plot(dataXPos,dataYPos,'color','r');
                        lostTrial(lostCount) = j;
                        lostCount = lostCount + 1;
                    end
                    title(['Hand Speeds ' blockCond{z} ' Approach']);
                    xlim([400 1500])
                    ylim([0 0.80])
                    ylabel('Y (cm)');
                    xlabel('X (ms)');
                else %plot the avoid condition for the other type of stimulus
                    subplot(2,2,3)
                    hold on
                    if (~isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'AVOIDED')))) %check if correctly avoided
                        plot((0:length(dataSpeed)-targetOnTime(j)),dataSpeed(targetOnTime(j):end),'color','b');
                    elseif (~isempty(find(contains(dataRun{i}(j).EVENTS.LABELS,'TIMED_OUT'))))
                        if (~isnan(targetOnTime(j)))
                            plot((0:length(dataSpeed)-targetOnTime(j)),dataSpeed(targetOnTime(j):end),'color','r');
                        end
                        lostTrial(lostCount) = j;
                        lostCount = lostCount + 1;
                    else %error trial
                        plot(dataXPos,dataYPos,'color','r');
                        lostTrial(lostCount) = j;
                        lostCount = lostCount + 1;
                    end
                    ylim([0 0.80])
                    xlim([400 1500])
                    title(['Avoid']);
                end
            end
        end
        % mydir  = pwd;
        % idcs   = strfind(mydir,'\');
        % newdir = mydir(1:idcs(end)-1);
        % set(gcf,'renderer','painters')
        % orient(a,'landscape')
        % print(a,'-fillpage',fullfile(mydir,['exemplar plot', typePlot, num2str(z)]),'-dpdf');
    end
    % set(gcf,'renderer','painters')
    % folderPath = fullfile(mydir,nameList{i});
    % writetable(struct2table(partInfo{i}),folderPath);
    % close all

    %% pull out bias scores for different task features (cue types, trial type)
    appPA = (trialType == 0 & appAvoid == 0);
    avPA = (trialType == 0 & appAvoid == 1);
    appSB = (trialType == 1 & appAvoid == 0);
    avSB = (trialType == 1 & appAvoid == 1);
    appNeut = (trialType > 1 & appAvoid == 0);
    avNeut = (trialType > 1 & appAvoid == 1);
    paNeut = (trialType == 0 | trialType > 1);
    sbNeut = (trialType > 0);

    reactBias(i,1) = ((mean(reactTime(i,avPA),'omitnan')-mean(reactTime(i,appPA),'omitnan'))-(mean(reactTime(i,avNeut),'omitnan')-mean(reactTime(i,appNeut),'omitnan')))/std(reactTime(i,paNeut),'omitnan'); %PA
    reactBias(i,2) = ((mean(reactTime(i,avSB),'omitnan')-mean(reactTime(i,appSB),'omitnan'))-(mean(reactTime(i,avNeut),'omitnan')-mean(reactTime(i,appNeut),'omitnan')))/std(reactTime(i,paNeut),'omitnan'); %SB

    speedBias(i,1) = ((mean(maxSpeed(i,avPA),'omitnan')-mean(maxSpeed(i,appPA),'omitnan'))-(mean(maxSpeed(i,avNeut),'omitnan')-mean(maxSpeed(i,appNeut),'omitnan')))/std(maxSpeed(i,paNeut),'omitnan'); %PA
    speedBias(i,2) = ((mean(maxSpeed(i,avSB),'omitnan')-mean(maxSpeed(i,appSB),'omitnan'))-(mean(maxSpeed(i,avNeut),'omitnan')-mean(maxSpeed(i,appNeut),'omitnan')))/std(maxSpeed(i,paNeut),'omitnan'); %SB

    moveBias(i,1) = ((mean(moveTime(i,avPA),'omitnan')-mean(moveTime(i,appPA),'omitnan'))-(mean(moveTime(i,avNeut),'omitnan')-mean(moveTime(i,appNeut),'omitnan')))/std(moveTime(i,paNeut),'omitnan'); %PA
    moveBias(i,2) = ((mean(moveTime(i,avSB),'omitnan')-mean(moveTime(i,appSB),'omitnan'))-(mean(moveTime(i,avNeut),'omitnan')-mean(moveTime(i,appNeut),'omitnan')))/std(moveTime(i,paNeut),'omitnan'); %SB

    dirBias(i,1) = ((mean(dirChng(i,avPA),'omitnan')-mean(dirChng(i,appPA),'omitnan'))-(mean(dirChng(i,avNeut),'omitnan')-mean(dirChng(i,appNeut),'omitnan')))/std(dirChng(i,paNeut),'omitnan'); %PA
    dirBias(i,2) = ((mean(dirChng(i,avSB),'omitnan')-mean(dirChng(i,appSB),'omitnan'))-(mean(dirChng(i,avNeut),'omitnan')-mean(dirChng(i,appNeut),'omitnan')))/std(dirChng(i,paNeut),'omitnan'); %SB

    distBias(i,1) = ((mean(oppDist(i,avPA),'omitnan')-mean(oppDist(i,appPA),'omitnan'))-(mean(oppDist(i,avNeut),'omitnan')-mean(oppDist(i,appNeut),'omitnan')))/std(oppDist(i,paNeut),'omitnan'); %PA
    distBias(i,2) = ((mean(oppDist(i,avSB),'omitnan')-mean(oppDist(i,appSB),'omitnan'))-(mean(oppDist(i,avNeut),'omitnan')-mean(oppDist(i,appNeut),'omitnan')))/std(oppDist(i,paNeut),'omitnan'); %SB

    array4base{i,1} = [reactTime(i,trialType == 0);maxSpeed(i,trialType == 0);moveTime(i,trialType == 0);dirChng(i,trialType == 0);oppDist(i,trialType == 0);]; %get array for heatmap use later
    array4base{i,2} = [reactTime(i,trialType == 1);maxSpeed(i,trialType == 1);moveTime(i,trialType == 1);dirChng(i,trialType == 1);oppDist(i,trialType == 1);]; %get array for heatmap use later
    array4base{i,3} = [reactTime(i,trialType > 1);maxSpeed(i,trialType > 1);moveTime(i,trialType > 1);dirChng(i,trialType > 1);oppDist(i,trialType > 1);]; %get array for heatmap use later
end

%organize array4corr to setup heatmap function
%requires Statistics and Machine Learning Toolbox (matlab function corr)
array4heatPA = array4base{1,1};
array4heatSB = array4base{1,2};
array4heatNeut = array4base{1,3};
for (i = 2:size(data,1))
    array4heatPA = horzcat(array4heatPA,array4base{i,1});
    array4heatSB = horzcat(array4heatSB,array4base{i,2});
    array4heatNeut = horzcat(array4heatNeut,array4base{i,3});
end
array4heatPA = array4heatPA';
array4heatSB = array4heatSB';
array4heatNeut = array4heatNeut';

%set the number of participants
for (i = 1:size(reactBias,1))
    avgRT(i,1) = mean(reactBias(i,1)); %PA bias for RT
    avgRT(i,2) = mean(reactBias(i,2)); %SB bias for RT
    avgMS(i,1) = mean(speedBias(i,1)); %PA bias for max speed
    avgMS(i,2) = mean(speedBias(i,2)); %SB bias for max speed
    avgMT(i,1) = mean(moveBias(i,1)); %PA bias for movement time
    avgMT(i,2) = mean(moveBias(i,2)); %SB bias for movement time
    avgDC(i,1) = mean(dirBias(i,1)); %PA bias for direction changes
    avgDC(i,2) = mean(dirBias(i,2)); %SB bias for direction changes
    avgOD(i,1) = mean(distBias(i,1)); %PA bias for speed peaks
    avgOD(i,2) = mean(distBias(i,2)); %SB bias for speed peaks
    % avgID(i,1) = avgInitDir(i,1)-avgInitDir(i,3); %PA bias for opposite distance
    % avgID(i,2) = avgInitDir(i,2)-avgInitDir(i,3); %SB bias for opposite distance
end

%get participant averages
avgRT(i+1,1) = mean(avgRT(:,1),'omitnan'); %for PA bias
avgRT(i+1,2) = mean(avgRT(:,2),'omitnan'); %for SB bias
avgMS(i+1,1) = mean(avgMS(:,1),'omitnan');
avgMS(i+1,2) = mean(avgMS(:,2),'omitnan');
avgMT(i+1,1) = mean(avgMT(:,1),'omitnan');
avgMT(i+1,2) = mean(avgMT(:,2),'omitnan');
avgDC(i+1,1) = mean(avgDC(:,1),'omitnan');
avgDC(i+1,2) = mean(avgDC(:,2),'omitnan');
avgOD(i+1,1) = mean(avgOD(:,1),'omitnan');
avgOD(i+1,2) = mean(avgOD(:,2),'omitnan');
% avgID(i+1,1) = mean(avgID(:,1),'omitnan');
% avgID(i+1,2) = mean(avgID(:,2),'omitnan');

%make heatmap to compare parameters
corrLabels = [{'Reaction Time'};{'Max Speed'};{'Move Time'};{'Direction Change'};{'Opposite Distance'};];
expLabels = [{'Physical Activity'};{'Sedentary Behaviour'};{'Neutral'}];
for (i = 1:size(corrLabels,1))
    for (j = 1:size(corrLabels,1))
        [corrArray(i,j), pArray(i,j)] = corr(array4heatPA(:,i),array4heatPA(:,j),'Type','spearman','rows','complete');
        negArray(i,j) = corrArray(i,j)>0;
        corrArray(i,j) = abs(round(corrArray(i,j),2));
    end
end
figure,
heatmap(corrLabels,corrLabels,corrArray)
title(expLabels{1})

for (i = 1:size(corrLabels,1))
    for (j = 1:size(corrLabels,1))
        [corrArray(i,j), pArray(i,j)] = corr(array4heatSB(:,i),array4heatSB(:,j),'Type','spearman','rows','complete');
        negArray(i,j) = corrArray(i,j)>0;
        corrArray(i,j) = abs(round(corrArray(i,j),2));
    end
end
figure,
heatmap(corrLabels,corrLabels,corrArray)
title(expLabels{2})

for (i = 1:size(corrLabels,1))
    for (j = 1:size(corrLabels,1))
        [corrArray(i,j), pArray(i,j)] = corr(array4heatNeut(:,i),array4heatNeut(:,j),'Type','spearman','rows','complete');
        negArray(i,j) = corrArray(i,j)>0;
        corrArray(i,j) = abs(round(corrArray(i,j),2));
    end
end
figure,
heatmap(corrLabels,corrLabels,corrArray)
title(expLabels{3})
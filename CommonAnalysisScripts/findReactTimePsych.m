function reactTime = findReactTimePsych(accel,i,j,posAccel)
%reaction time based on first instance that acceleration went from
%1000mm/sec^2 to 200mm/sec^2

minRT = 150; %minimum reaction time of 150ms (adjusted for use in 200Hz)
accelMax = 1+posAccel;
accelMin = 0.2;

accelCheck = find(accel>accelMax);
if (isempty(accelCheck))
    [~,accelCheck] = max(accel);
end

accelCheck(accelCheck<minRT) = [];
firstAcc = accelCheck(1);

accelBot = find(accel<accelMin);
minAcc = accelBot(max(find(accelBot<firstAcc)));

reactTime = minAcc;
if (reactTime < minRT)
    reactTime = [];
end

if (isempty(reactTime))
    reactTime = nan;
end

if (i == 2 && j == 11)
    kk = 1;
end

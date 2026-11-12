function reactTime = findReactTimeAAT(speed,i,j)
%same as other reaction time algorithms
reactTime = 0;
counter = 1;

[peaks,peakTimes] = findpeaks(speed);
maxSpeed = max(speed);
if (maxSpeed > max(peaks))
    peakSpeed = maxSpeed;
    maxPeakTime = find(speed == peakSpeed);
else
    peakSpeed = max(peaks);
    maxPeakTime = peakTimes(find(peaks == peakSpeed));
end

reactTimeThresh = 0.05*maxSpeed;

for (i = maxPeakTime:-1:1)
    if (speed(i)<reactTimeThresh)
        reactTimeArray(counter) = i;
        counter = counter + 1;
    end
end
reactTime = reactTimeArray(1);
if (reactTime < 200)
    reactTime = nan;
end
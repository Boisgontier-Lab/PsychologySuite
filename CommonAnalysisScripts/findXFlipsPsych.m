function xFlips = findXFlipsPsych(posX,posY,speedX,speedY,reachDir,suiteNum,appAvoid,i,j)
%get the number of changes in movement direction along the task x-axis
%only count sign changes in x-velocity that are followed by >1 mm displacement
%in the new direction

reachThresh = 0.002;
if (suiteNum == 1 || suiteNum == 2)
    if (reachDir == 1)
        speedX = -speedX;
        reachAngle = 180;
    else
        reachAngle = 0;
    end
end

if (suiteNum == 3)
    reachAngle = -1;
elseif (suiteNum == 4)
    angles = rad2deg([0:pi/6:2*pi-pi/6]);
    reachAngle = (angles(reachDir));
    if (appAvoid == 1)
        if (reachAngle < 180)
            reachAngle = reachAngle+180;
        else
            reachAngle = reachAngle-180;
        end
    end
end

%rotate position and velocity so the instructed movement direction is
%aligned with the positive x-axis
posRot = [posX posY]*[cosd(reachAngle), -sind(reachAngle) ;sind(reachAngle), cosd(reachAngle)];
speedRot = [speedX speedY]*[cosd(reachAngle), -sind(reachAngle) ;sind(reachAngle), cosd(reachAngle)];

xPos = posRot(:,1)-posRot(1,1);
xSpeed = speedRot(:,1);

%identify non-zero x-velocity samples so that samples exactly equal to
%zero do not create artificial additional sign changes
nonZeroIndex = find(xSpeed ~= 0 & ~isnan(xSpeed) & ~isnan(xPos));

xFlips = 0;

if (length(nonZeroIndex) > 1)
    nonZeroSign = sign(xSpeed(nonZeroIndex));

    %a flip occurs when the sign of x-velocity changes between two
    %successive non-zero velocity samples
    flipIndexInNonZero = find(nonZeroSign(2:end) ~= nonZeroSign(1:end-1)) + 1;

    %for each sign change, measure displacement in the new direction
    %until the next sign change (or the end of the movement)
    for (k = 1:length(flipIndexInNonZero))
        segmentStartNZ(k) = flipIndexInNonZero(k);

        if (k < length(flipIndexInNonZero))
            segmentEndNZ(k) = flipIndexInNonZero(k+1)-1;
        else
            segmentEndNZ(k) = length(nonZeroIndex);
        end

        segmentStart(k) = nonZeroIndex(segmentStartNZ(k));
        segmentEnd(k) = nonZeroIndex(segmentEndNZ(k));

        displacement(k) = (abs(xPos(segmentEnd(k)))>reachThresh & abs(xPos(segmentStart(k)))>reachThresh);

        if (displacement(k))
            xFlips = xFlips + 1;
        end
    end
end

if (i == 1 && j == 82)
    g = 1;
end

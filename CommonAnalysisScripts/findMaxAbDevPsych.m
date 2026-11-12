function mad = findMaxAbDevPsych(dataX,dataY,reachSpot,dataTable,i,j)
%flatten hand path to the x-axis and then check maximum vertical deviation

xLocs = dataTable.X(4:7)-dataTable.X(2);
yLocs = dataTable.Y(4:7)-dataTable.Y(2);

for (i = 1:4)
    angles(i) = mod(atan2d(yLocs(i),xLocs(i)),360);
end

reachAngle = (angles(reachSpot));
maxReachDist = hypot(dataX(end)-dataX(1),dataY(end)-dataY(1));
startX = dataX(1);
startY = dataY(1);

endX = startX+maxReachDist*cosd(reachAngle);
endY = startY+maxReachDist*sind(reachAngle);

lineRot = [linspace(startX,endX,size(dataX,1))' linspace(startY,endY,size(dataY,1))']*[cosd(reachAngle) -sind(reachAngle) ;sind(reachAngle) cosd(reachAngle)];
dataRot = [dataX dataY]*[cosd(reachAngle) -sind(reachAngle) ;sind(reachAngle) cosd(reachAngle)];
diffLine = abs(dataRot(:,2)-lineRot(1,2));
mad = max(diffLine)*100;

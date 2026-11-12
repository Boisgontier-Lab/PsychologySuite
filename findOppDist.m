function oppDistance = findOppDist(pos,side,i,j)
%get furthest distance participant's hand moved in the direction they
%weren't supposed to
oppDistance = 0;

if (side == 1) %flip the position of the hand if the movement was left
    pos = -pos;
end

oppDistance = pos(1)*100-min(pos)*100; %get furthest distance travelled in the opposite direction relative to the hand starting point

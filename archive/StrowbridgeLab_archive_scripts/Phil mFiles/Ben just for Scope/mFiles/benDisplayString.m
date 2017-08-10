function outString = benDisplayString(inNum)
% this routine processes a double for proper display on Scope form

if inNum >-9999 && inNum < 9999
    outString=sprintf('%.1f',inNum);
else
    outString=sprintf(['%10.' sprintf('%0.0f', 6 - log(inNum)) 'f'], inNum);
end

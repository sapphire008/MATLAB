function outPath = epi2path(inString, rootPath)
% function to get the full file path from the short episode text

if nargin < 2
    rootPath = 'W:\Larimer\';
end

shortMonths = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
longMonths = {'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'};
dot = find(inString == '.', 1, 'first');
if isempty(dot)
    scores = find(inString == '_');
    dot = find(inString < 58 & inString > 47, 1, 'first') - 1;
    inString(scores(scores < dot)) = ' ';
    inString(scores(scores >= dot)) = '.';
end
if inString(dot + 1) == '0'
    outPath = [rootPath '20' inString(dot + (6:7)) filesep longMonths{strcmpi(inString(dot + (3:5)), shortMonths)} filesep longMonths{strcmpi(inString(dot + (3:5)), shortMonths)} ' ' inString(dot + 2) ' 20' inString(dot + (6:7)) filesep inString];
else
    outPath = [rootPath '20' inString(dot + (6:7)) filesep longMonths{strcmpi(inString(dot + (3:5)), shortMonths)} filesep longMonths{strcmpi(inString(dot + (3:5)), shortMonths)} ' ' inString(dot + (1:2)) ' 20' inString(dot + (6:7)) filesep inString];
end
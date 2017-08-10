function outPath = path2epi(inString)
% function to get the short file name from the path
if iscell(inString)
    outPath = {};
    for i = 1:numel(inString)
        outPath{end + 1} = inString{1}(1:find(inString{i} == filesep, 1, 'last'));
    end
else
    outPath = inString(1:find(inString == filesep, 1, 'last'));
end
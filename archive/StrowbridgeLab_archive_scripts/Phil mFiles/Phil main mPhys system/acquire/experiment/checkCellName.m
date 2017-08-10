function checkCellName
badChars = {'.', '\', '/', ':', '?', '"', '<', '>', '|'};
cellName = get(findobj('tag', 'cellName'), 'string');
newName = cellName;

for i = badChars
    newName(newName == i{1}) = '_';
end

if ~strcmp(cellName, newName)
    set(findobj('tag', 'cellName'), 'string', newName);
    warning([cellName ' is not a valid cell name.  Cell names can not contain ' cell2mat(badChars)]);    
end
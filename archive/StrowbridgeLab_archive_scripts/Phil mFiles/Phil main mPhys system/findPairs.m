load('C:\Users\twoPhotonB\Desktop\Desktop\preParsej.mat');

A = true(numel(headers), 1);
for headerIndex = 1:numel(headers)
%     A(headerIndex) = A(headerIndex) && ~iscell(headers(headerIndex).drug) && ~isempty(strfind(headers(headerIndex).drug, 'APV'));    
%     A(headerIndex) = A(headerIndex) && (any(strcmp(headers(headerIndex).ampCellLocationName, 'IML')) || any(strcmp(headers(headerIndex).ampCellLocationName, 'DGCL')));
    if size(headers(headerIndex).ttlEnable, 1) > 1
        A(headerIndex) = A(headerIndex) && (any(cellfun(@(x) ~isempty(x), strfind(headers(headerIndex).ttlTypeName, 'Puff'))' & cell2mat(headers(headerIndex).ttlEnable)));    
    else
        A(headerIndex) = A(headerIndex) && (any(cellfun(@(x) ~isempty(x), strfind(headers(headerIndex).ttlTypeName, 'Puff')) & cell2mat(headers(headerIndex).ttlEnable)));    
    end
%     A(headerIndex) = A(headerIndex) && (numel(headers(headerIndex).ampCellLocationName) > 1 && ~any(strcmp(headers(headerIndex).ampCellLocationName, 'Unknown')));
end
whichHeaders = find(A);

whichCell = [];
whichEpi = {};
for cellIndex = 1:numel(parseData)
    numEpis = 0;
    for epiIndex = 1:numel(parseData(cellIndex).episodes)
        if ismember(parseData(cellIndex).episodes{epiIndex}.headerIndex, whichHeaders)
            numEpis = numEpis + 1;
            whichEpi{numel(whichCell) + 1}(numEpis) = epiIndex;
        end
    end
    if numEpis
        whichCell(end + 1) = cellIndex;
    end
end    


whichCell = {parseData(whichCell).key}';

bCell = whichCell;
for i = 1:numel(bCell)
    bCell{i} = bCell{i}(1:find(bCell{i}=='.', 1,'last')-1);
end
bCell = unique(bCell);
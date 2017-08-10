A = false(numel(headers), 1);
for headerIndex = 1:numel(headers)
    for a = 1:size(headers(headerIndex).ttlIntensity, 1)
        A(headerIndex) = A(headerIndex) || (headers(headerIndex).ttlEnable{a} == 1 && headers(headerIndex).ttlIntensity{a} <= 50 && strcmp(headers(headerIndex).ampCellLocationName{1}, 'Hilar') && strcmp(headers(headerIndex).ttlTypeName{a},'SIU, tungsten, PP'));
    end
end
whichHeaders = find(A);

%         A(headerIndex) = A(headerIndex) || (headers(headerIndex).ttlEnable{a} == 1 && sum(cell2mat(headers(headerIndex).ampEnable)) > 2);
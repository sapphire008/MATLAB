function p = comparePSPs(Group1, Group2)

grpData1 = zeros(0, 4);
grpData2 = zeros(0,4);

for i = 1:numel(Group1.params)
    if ~isempty(Group1.params{i})
        grpData1 = [grpData1; Group1.params{i}];%(Group1.params{i}(:,3) <= 1009 & Group1.params{i}(:,3) >= 1000,:)];
    end
end
for i = 1:numel(Group2.params)
    if ~isempty(Group2.params{i})
        grpData2 = [grpData2; Group2.params{i}];
    end
end

[h p] = ttest2(grpData1, grpData2);
p(3) = poisscdf(size(grpData1, 1) / numel(Group1.params), size(grpData2, 1) / numel(Group2.params));
if size(grpData1, 1) / numel(Group1.params) < size(grpData2, 1) / numel(Group2.params)
    p(3) = 1-p;
end
dataHolder = nan(max([size(grpData1, 1) size(grpData2, 1)]), 8);
dataHolder(1:size(grpData1, 1), 1:3) = grpData1(:,[1 2 4]);
dataHolder(1:size(grpData2, 1), 5:7) = grpData2(:,[1 2 4]);
dataHolder(1,4) = size(grpData1, 1) / numel(Group1.params);
dataHolder(2,4) = p(3);
dataHolder(1,8) = size(grpData2, 1) / numel(Group2.params);

title = get(getappdata(0, 'scopes'), 'name');
outText = ['Driven' char(9) char(9) char(9) char(9) 'Spontaneous' char(9) char(9) title(find(title == filesep, 1, 'last') + 1:end) char(13) 'Amp (pA)' char(9) 'Rise (ms)' char(9) 'Decay (ms)' char(9) 'Events per episode' char(9) 'Amp (pA)' char(9) 'Rise (ms)' char(9) 'Decay (ms)' char(9) 'Events per episode' char(13)];
for i = 1:7
    if i == 4
        outText = [outText char(9)];
    else
        outText = [outText '=average(' char(i + 64) '7:' char(i + 64) sprintf('%0.0f', size(dataHolder, 1) + 7) ')' char(9)];
    end
end
outText = [outText char(13)];
for i = 1:7
    if i == 4
        outText = [outText char(9)];
    else
        outText = [outText '=stdev(' char(i + 64) '7:' char(i + 64) sprintf('%0.0f', size(dataHolder, 1) + 7) ')/sqrt(count(' char(i + 64) '7:' char(i + 64) sprintf('%0.0f', size(dataHolder, 1) + 7) ') - 1)' char(9)];
    end
end
outText = [outText char(13)];
for i = 1:3
    outText = [outText '=ttest(' char(i + 64) '7:' char(i + 64) sprintf('%0.0f', size(dataHolder, 1) + 7) ', ' char(i + 68) '7:' char(i + 68) sprintf('%0.0f', size(dataHolder, 1) + 7) ', 2, 2)' char(9)];
end
outText = [outText char(13) char(13)];


dataText =  num2str(dataHolder, '%1.6f\t');
for i = 1:size(dataText, 1)
    outText = [outText char(13) dataText(i,:)];
end
clipboard('copy', outText);

if ~nargout
    disp('Group 1 vs. Group 2');
    disp(['Amp: ' sprintf('%1.2f', mean(grpData1(:,1))) ' ' char(177) ' ' sprintf('%1.2f', std(grpData1(:,1)) ./ sqrt(size(grpData1, 1)-1)) ' vs. ' sprintf('%1.2f', mean(grpData2(:,1))) ' ' char(177) ' ' sprintf('%1.2f', std(grpData2(:,1)) ./ sqrt(size(grpData2, 1)-1)) ' pA, p = ' sprintf('%1.4f', p(1))]);
    disp(['Rise: ' sprintf('%1.2f', mean(grpData1(:,2))) ' ' char(177) ' ' sprintf('%1.2f', std(grpData1(:,2)) ./ sqrt(size(grpData1, 1)-1)) ' vs. ' sprintf('%1.2f', mean(grpData2(:,2))) ' ' char(177) ' ' sprintf('%1.2f', std(grpData2(:,2)) ./ sqrt(size(grpData2, 1)-1)) ' ms, p = ' sprintf('%1.4f', p(2))]);
    disp(['Rate: ' sprintf('%1.2f', size(grpData1,1) / numel(Group1.params)) ' vs. ' sprintf('%1.2f', size(grpData2,1) / numel(Group2.params)) ' per episode, p = ' sprintf('%1.4f', p(3))]);
    disp(['Decay: ' sprintf('%1.2f', mean(grpData1(:,4))) ' ' char(177) ' ' sprintf('%1.2f', std(grpData1(:,4)) ./ sqrt(size(grpData1, 1)-1)) ' vs. ' sprintf('%1.2f', mean(grpData2(:,4))) ' ' char(177) ' ' sprintf('%1.2f', std(grpData2(:,4)) ./ sqrt(size(grpData2, 1)-1)) ' ms, p = ' sprintf('%1.4f', p(4))]);
end

tauBins = 2.5:5:97.5;
cBins = hist(grpData1(:,2),tauBins);
dBins = hist(grpData2(:,2),tauBins);

ampBins = 5:10:195;
eBins = hist(abs(grpData1(:,1)),ampBins);
fBins = hist(abs(grpData2(:,1)),ampBins);

clipboard('copy', num2str([eBins fBins], '%1.6f\t'))

return
clipboard('copy', num2str([mean(grpData1(:,1)) mean(grpData1(:,2)) size(grpData1,1) / numel(Group1.params) mean(grpData1(:,4)) mean(grpData2(:,1)) mean(grpData2(:,2)) size(grpData2,1) / numel(Group2.params) mean(grpData2(:,4)) numel(Group1.params) numel(Group2.params) cBins dBins eBins fBins], '%1.6f\t'))

figure;
subplot(4,1,1);
cBins = cBins ./ numel(Group1.params);
bar(tauBins, cBins);
ylabel('Group1 per epi');
subplot(4,1,2);
dBins = dBins ./ numel(Group2.params);
bar(tauBins, dBins);
ylabel('Group2 per epi');
subplot(4,1,3:4);
bar(tauBins, (cBins - dBins) ./ cBins);
ylabel('DGC sensitive (%)')
xlabel('Tau (ms)');
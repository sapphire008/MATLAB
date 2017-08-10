controlData = zeros(0, 4);
dcgData = zeros(0,4);

for i = 1:numel(Control.params)
    controlData = [controlData; Control.params{i}];
end
for i = 1:numel(DCG.params)
    dcgData = [dcgData; DCG.params{i}];
end

[h p] = ttest2(controlData, dcgData);

disp(['Amp: ' sprintf('%1.2f', mean(controlData(:,1))) ' ' char(177) ' ' sprintf('%1.2f', std(controlData(:,1)) ./ sqrt(size(controlData, 1)-1)) ' vs. ' sprintf('%1.2f', mean(dcgData(:,1))) ' ' char(177) ' ' sprintf('%1.2f', std(dcgData(:,1)) ./ sqrt(size(dcgData, 1)-1)) ' pA, p = ' sprintf('%1.4f', p(1))]);
disp(['Tau: ' sprintf('%1.2f', mean(controlData(:,2))) ' ' char(177) ' ' sprintf('%1.2f', std(controlData(:,2)) ./ sqrt(size(controlData, 1)-1)) ' vs. ' sprintf('%1.2f', mean(dcgData(:,2))) ' ' char(177) ' ' sprintf('%1.2f', std(dcgData(:,2)) ./ sqrt(size(dcgData, 1)-1)) ' ms, p = ' sprintf('%1.4f', p(2))]);
disp(['Rate: ' sprintf('%1.2f', size(controlData,1) / numel(Control.params)) ' vs. ' sprintf('%1.2f', size(dcgData,1) / numel(DCG.params)) ' per episode, p = ' sprintf('%1.4f', poisscdf(size(controlData, 1) / numel(Control.params), size(dcgData, 1) / numel(DCG.params)))]);
disp(['Offset: ' sprintf('%1.2f', mean(controlData(:,4))) ' ' char(177) ' ' sprintf('%1.2f', std(controlData(:,4)) ./ sqrt(size(controlData, 1)-1)) ' vs. ' sprintf('%1.2f', mean(dcgData(:,4))) ' ' char(177) ' ' sprintf('%1.2f', std(dcgData(:,4)) ./ sqrt(size(dcgData, 1)-1)) ' pA, p = ' sprintf('%1.4f', p(4))]);

tauBins = 2.5:5:97.5;
cBins = hist(controlData(:,2),tauBins);
dBins = hist(dcgData(:,2),tauBins);

ampBins = 5:10:195;
eBins = hist(abs(controlData(:,1)),ampBins);
fBins = hist(abs(dcgData(:,1)),ampBins);

clipboard('copy', num2str(eBins, '%1.6f\t'))

clipboard('copy', num2str([mean(controlData(:,1)) mean(controlData(:,2)) size(controlData,1) / numel(Control.params) mean(controlData(:,4)) mean(dcgData(:,1)) mean(dcgData(:,2)) size(dcgData,1) / numel(DCG.params) mean(dcgData(:,4)) numel(Control.params) numel(DCG.params) cBins dBins eBins fBins], '%1.6f\t'))

figure;
subplot(4,1,1);
cBins = cBins ./ numel(Control.params);
bar(tauBins, cBins);
ylabel('Control per epi');
subplot(4,1,2);
dBins = dBins ./ numel(DCG.params);
bar(tauBins, dBins);
ylabel('DCG per epi');
subplot(4,1,3:4);
bar(tauBins, (cBins - dBins) ./ cBins);
ylabel('DGC sensitive (%)')
xlabel('Tau (ms)');
% for use with Cell D.18Mar09.S3.E1-48,51-52
meanData = mean(zData.traceData{2}, 2);
errData = std(zData.traceData{2},0,2)./sqrt(49);
indices = [25 1 3 5; 7 27 13 15; 9 17 29 21; 11 19 23 31] * 5000;
xData = -10:.2:100;
xIndices = -50:500;

% plot raw covariance matrix (with estimated covariances)
figure
for i = 1:4
    for j = 1:4
        subplot(4,4,(i - 1) * 4 + j);
        line(xData, meanData(indices(i,j) + xIndices), 'color', 'k', 'lineWidth', 2);
        line(xData, meanData(indices(i,j) + xIndices) - errData(indices(i,j) + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
        line(xData, meanData(indices(i,j) + xIndices) + errData(indices(i,j) + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');        
        
        if i ~=j
            line(xData, meanData(5000*25 + 10000*(i-1) + xIndices) + meanData(5000*25 + 10000*(j-1) + xIndices - 5) - mean(meanData(5000*25 + 10000*(j-1) - (5:10))), 'color', 'b', 'lineWidth', 2);
        end
        set(gca, 'xlim', [xData(1) xData(end)]);
        set(gca, 'ylim', [-72 -52]);
    end
end
subplot(4,4,1)
title('Second Stim');
ylabel('First Stim');

% plot orderings
figure
for i = 1:4
    for j = 1:4
        if i > j
            subplot(3,3,(i - 2) * 3 + j);
            line(xData, meanData(indices(i,j) + xIndices), 'color', 'k', 'lineWidth', 2);
            line(xData, meanData(indices(i,j) + xIndices) - errData(indices(i,j) + xIndices), 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');
            line(xData, meanData(indices(i,j) + xIndices) + errData(indices(i,j) + xIndices), 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');        

            line(xData, meanData(indices(j,i) + xIndices), 'color', 'r', 'lineWidth', 2);
            line(xData, meanData(indices(j,i) + xIndices) - errData(indices(j,i) + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
            line(xData, meanData(indices(j,i) + xIndices) + errData(indices(j,i) + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');        

            set(gca, 'xlim', [xData(1) xData(end)]);
            set(gca, 'ylim', [-72 -52]);
        end
    end
end
subplot(3,3,1)
title('Second Stim');
ylabel('First Stim');
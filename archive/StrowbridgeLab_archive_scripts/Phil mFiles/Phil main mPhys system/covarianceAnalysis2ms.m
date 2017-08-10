% for use with Cell C.18Mar09.S3.E53-63,S4.E53-62,S5.E52-63 (any with APs removed)
meanData = mean(zData.traceData{2}, 2);
errData = std(zData.traceData{2},0,2)./sqrt(31);

% for use with Cell C.18Mar09.S3.E1-16,18-52 (any with APs removed)
meanDataABCD = mean(zData.traceData{2}, 2);
errDataABCD = std(zData.traceData{2},0,2)./sqrt(50);

% for use with Cell C.18Mar09.S4.E1-25,27-48,50-51 (any with APs removed)
meanDataACBD = mean(zData.traceData{2}, 2);
errDataACBD = std(zData.traceData{2},0,2)./sqrt(48);

% for use with Cell C.18Mar09.S5.E1-52 (any with APs removed)
meanDataADBC = mean(zData.traceData{2}, 2);
errDataADBC = std(zData.traceData{2},0,2)./sqrt(51);

xData = -10:.2:100;
xIndices = -50:500;

% plot raw covariance matrix (with estimated covariances)
figure
h(1) = subplot(4,4,2);
    line(xData, meanDataABCD(5000 * 1 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataABCD(5000 * 1 + xIndices) - errDataABCD(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataABCD(5000 * 1 + xIndices) + errDataABCD(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');     
    line(xData, meanData(5000 * 1 + xIndices) + meanData(5000 * 2.5 + xIndices - 5) - mean(meanData(5000 * 2.5 - (5:10))), 'color', 'b', 'lineWidth', 2);
h(2) = subplot(4,4,12);
    line(xData, meanDataABCD(5000 * 2.5 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataABCD(5000 * 2.5 + xIndices) - errDataABCD(5000 * 2.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataABCD(5000 * 2.5 + xIndices) + errDataABCD(5000 * 2.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');        
    line(xData, meanData(5000 * 4 + xIndices) + meanData(5000 * 5.5 + xIndices - 5) - mean(meanData(5000 * 5.5 - (5:10))), 'color', 'b', 'lineWidth', 2);    
h(3) = subplot(4,4,5);
    line(xData, meanDataABCD(5000 * 4 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataABCD(5000 * 4 + xIndices) - errDataABCD(5000 * 4 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataABCD(5000 * 4 + xIndices) + errDataABCD(5000 * 4 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');     
    line(xData, meanData(5000 * 2.5 + xIndices) + meanData(5000 * 1 + xIndices - 5) - mean(meanData(5000 * 1 - (5:10))), 'color', 'b', 'lineWidth', 2);    
h(4) = subplot(4,4,15);
    line(xData, meanDataABCD(5000 * 5.5 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataABCD(5000 * 5.5 + xIndices) - errDataABCD(5000 * 5.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataABCD(5000 * 5.5 + xIndices) + errDataABCD(5000 * 5.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');    
    line(xData, meanData(5000 * 5.5 + xIndices) + meanData(5000 * 4 + xIndices - 5) - mean(meanData(5000 * 4 - (5:10))), 'color', 'b', 'lineWidth', 2);    
h(5) = subplot(4,4,3);
    line(xData, meanDataACBD(5000 * 1 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataACBD(5000 * 1 + xIndices) - errDataACBD(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataACBD(5000 * 1 + xIndices) + errDataACBD(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':'); 
    line(xData, meanData(5000 * 1 + xIndices) + meanData(5000 * 4 + xIndices - 5) - mean(meanData(5000 * 4 - (5:10))), 'color', 'b', 'lineWidth', 2);    
h(6) = subplot(4,4,8);
    line(xData, meanDataACBD(5000 * 2.5 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataACBD(5000 * 2.5 + xIndices) - errDataACBD(5000 * 2.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataACBD(5000 * 2.5 + xIndices) + errDataACBD(5000 * 2.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');        
    line(xData, meanData(5000 * 2.5 + xIndices) + meanData(5000 * 5.5 + xIndices - 5) - mean(meanData(5000 * 5.5 - (5:10))), 'color', 'b', 'lineWidth', 2);    
h(7) = subplot(4,4,9);
    line(xData, meanDataACBD(5000 * 4 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataACBD(5000 * 4 + xIndices) - errDataACBD(5000 * 4 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataACBD(5000 * 4 + xIndices) + errDataACBD(5000 * 4 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');    
    line(xData, meanData(5000 * 4 + xIndices) + meanData(5000 * 1 + xIndices - 5) - mean(meanData(5000 * 1 - (5:10))), 'color', 'b', 'lineWidth', 2);    
h(8) = subplot(4,4,14);
    line(xData, meanDataACBD(5000 * 5.5 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataACBD(5000 * 5.5 + xIndices) - errDataACBD(5000 * 5.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataACBD(5000 * 5.5 + xIndices) + errDataACBD(5000 * 5.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');     
    line(xData, meanData(5000 * 5.5 + xIndices) + meanData(5000 * 2.5 + xIndices - 5) - mean(meanData(5000 * 2.5 - (5:10))), 'color', 'b', 'lineWidth', 2);    
h(9) = subplot(4,4,4);
    line(xData, meanDataADBC(5000 * 1 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataADBC(5000 * 1 + xIndices) - errDataADBC(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataADBC(5000 * 1 + xIndices) + errDataADBC(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');        
    line(xData, meanData(5000 * 1 + xIndices) + meanData(5000 * 5.5 + xIndices - 5) - mean(meanData(5000 * 5.5 - (5:10))), 'color', 'b', 'lineWidth', 2);    
h(10) = subplot(4,4,7);
    line(xData, meanDataADBC(5000 * 2.5 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataADBC(5000 * 2.5 + xIndices) - errDataADBC(5000 * 2.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataADBC(5000 * 2.5 + xIndices) + errDataADBC(5000 * 2.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');    
    line(xData, meanData(5000 * 2.5 + xIndices) + meanData(5000 * 4 + xIndices - 5) - mean(meanData(5000 * 4 - (5:10))), 'color', 'b', 'lineWidth', 2);    
h(11) = subplot(4,4,13);
    line(xData, meanDataADBC(5000 * 4 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataADBC(5000 * 4 + xIndices) - errDataADBC(5000 * 4 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataADBC(5000 * 4 + xIndices) + errDataADBC(5000 * 4 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');   
    line(xData, meanData(5000 * 5.5 + xIndices) + meanData(5000 * 1 + xIndices - 5) - mean(meanData(5000 * 1 - (5:10))), 'color', 'b', 'lineWidth', 2);    
h(12) = subplot(4,4,10);
    line(xData, meanDataADBC(5000 * 5.5 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataADBC(5000 * 5.5 + xIndices) - errDataADBC(5000 * 5.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataADBC(5000 * 5.5 + xIndices) + errDataADBC(5000 * 5.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');  
    line(xData, meanData(5000 * 4 + xIndices) + meanData(5000 * 2.5 + xIndices - 5) - mean(meanData(5000 * 2.5 - (5:10))), 'color', 'b', 'lineWidth', 2);    
h(13) = subplot(4,4,1);
    line(xData, meanData(5000 * 1 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanData(5000 * 1 + xIndices) - errData(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanData(5000 * 1 + xIndices) + errData(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');  
h(14) = subplot(4,4,6);
    line(xData, meanData(5000 * 2.5 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanData(5000 * 2.5 + xIndices) - errData(5000 * 2.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanData(5000 * 2.5 + xIndices) + errData(5000 * 2.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');  
h(15) = subplot(4,4,11);
    line(xData, meanData(5000 * 4 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanData(5000 * 4 + xIndices) - errData(5000 * 4 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanData(5000 * 4 + xIndices) + errData(5000 * 4 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');  
h(16) = subplot(4,4,16);
    line(xData, meanData(5000 * 5.5 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanData(5000 * 5.5 + xIndices) - errData(5000 * 5.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanData(5000 * 5.5 + xIndices) + errData(5000 * 5.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');      
set(h, 'xlim', [xData(1) xData(end)]);
set(h, 'ylim', [-72 -52]);
subplot(4,4,1)
title('Second Stim');
ylabel('First Stim');
    
clear h
% plot raw covariance matrix (with estimated covariances)
figure
h(1) = subplot(3,3,1);
    line(xData, meanDataABCD(5000 * 4 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataABCD(5000 * 4 + xIndices) - errDataABCD(5000 * 4 + xIndices), 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataABCD(5000 * 4 + xIndices) + errDataABCD(5000 * 4 + xIndices), 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');        
    line(xData, meanDataABCD(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 2);
    line(xData, meanDataABCD(5000 * 1 + xIndices) - errDataABCD(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataABCD(5000 * 1 + xIndices) + errDataABCD(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');        
h(2) = subplot(3,3,9);
    line(xData, meanDataABCD(5000 * 2.5 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataABCD(5000 * 2.5 + xIndices) - errDataABCD(5000 * 2.5 + xIndices), 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataABCD(5000 * 2.5 + xIndices) + errDataABCD(5000 * 2.5 + xIndices), 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');        
    line(xData, meanDataABCD(5000 * 5.5 + xIndices), 'color', 'r', 'lineWidth', 2);
    line(xData, meanDataABCD(5000 * 5.5 + xIndices) - errDataABCD(5000 * 5.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataABCD(5000 * 5.5 + xIndices) + errDataABCD(5000 * 5.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');        
h(3) = subplot(3,3,4);
    line(xData, meanDataACBD(5000 * 4 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataACBD(5000 * 4 + xIndices) - errDataACBD(5000 * 4 + xIndices), 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataACBD(5000 * 4 + xIndices) + errDataACBD(5000 * 4 + xIndices), 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');        
    line(xData, meanDataACBD(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 2);
    line(xData, meanDataACBD(5000 * 1 + xIndices) - errDataACBD(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataACBD(5000 * 1 + xIndices) + errDataACBD(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');        
h(4) = subplot(3,3,8);
    line(xData, meanDataACBD(5000 * 5.5 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataACBD(5000 * 5.5 + xIndices) - errDataACBD(5000 * 5.5 + xIndices), 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataACBD(5000 * 5.5 + xIndices) + errDataACBD(5000 * 5.5 + xIndices), 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');        
    line(xData, meanDataACBD(5000 * 2.5 + xIndices), 'color', 'r', 'lineWidth', 2);
    line(xData, meanDataACBD(5000 * 2.5 + xIndices) - errDataACBD(5000 * 2.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataACBD(5000 * 2.5 + xIndices) + errDataACBD(5000 * 2.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');        
h(5) = subplot(3,3,7);
    line(xData, meanDataADBC(5000 * 4 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataADBC(5000 * 4 + xIndices) - errDataADBC(5000 * 4 + xIndices), 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataADBC(5000 * 4 + xIndices) + errDataADBC(5000 * 4 + xIndices), 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');        
    line(xData, meanDataADBC(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 2);
    line(xData, meanDataADBC(5000 * 1 + xIndices) - errDataADBC(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataADBC(5000 * 1 + xIndices) + errDataADBC(5000 * 1 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');        
h(6) = subplot(3,3,5);
    line(xData, meanDataADBC(5000 * 5.5 + xIndices), 'color', 'k', 'lineWidth', 2);
    line(xData, meanDataADBC(5000 * 5.5 + xIndices) - errDataADBC(5000 * 5.5 + xIndices), 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataADBC(5000 * 5.5 + xIndices) + errDataADBC(5000 * 5.5 + xIndices), 'color', 'k', 'lineWidth', 1, 'lineStyle', ':');        
    line(xData, meanDataADBC(5000 * 2.5 + xIndices), 'color', 'r', 'lineWidth', 2);
    line(xData, meanDataADBC(5000 * 2.5 + xIndices) - errDataADBC(5000 * 2.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');
    line(xData, meanDataADBC(5000 * 2.5 + xIndices) + errDataADBC(5000 * 2.5 + xIndices), 'color', 'r', 'lineWidth', 1, 'lineStyle', ':');        
set(h, 'xlim', [xData(1) xData(end)]);
set(h, 'ylim', [-72 -52]);
subplot(3,3,1)
title('Second Stim');
ylabel('First Stim');
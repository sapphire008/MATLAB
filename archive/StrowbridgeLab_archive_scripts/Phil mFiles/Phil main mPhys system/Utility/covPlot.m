function covData = covPlot(inData, dataNames)
% plot normalized covariances and R^2 values
% covData = covPlot(inData);

    if nargin < 2
        for i = 1:size(inData, 2)
            dataNames{i} = ['Column ' sprintf('%0.0f', i)];
        end
    end

    corVals = corrcoef(inData);
    corVals = corVals .^ 2;
    figure('name', 'Covariance', 'numbertitle', 'off');
    
    % find dimensions
    xDim = fix(sqrt(max(cumsum(1:size(inData, 2) - 1)))) + 1;
    if xDim * xDim - xDim >= size(max(cumsum(1:size(inData, 2))), 1)
        yDim = xDim - 1;
    else
        yDim = xDim;
    end
    
    % generate plots
    plotIndex = 1;
    for plotX = 1:size(inData, 2)
        for plotY = 1:plotX - 1
            subplot(xDim, yDim, plotIndex);
            plotIndex = plotIndex + 1;
            plot(inData(:, plotX), inData(:, plotY), 'linestyle', 'none', 'marker', '.', 'markerSize', 12)
            m = polyfit(inData(:, plotX), inData(:, plotY), 1);
            line([min(inData(:, plotX)) max(inData(:, plotX))], [m(1) * min(inData(:, plotX)) + m(2) m(1) * max(inData(:, plotX)) + m(2)], 'color', [1 0 0])
            title([dataNames{plotY} ' vs. ' dataNames{plotX} ', R^{2} = ' sprintf('%4.2f', corVals(plotX, plotY))])
            axis tight;
        end
    end
    
    covData = cov(normalizeMatrix(inData));
    
    figure('numbertitle', 'off', 'name', 'Covariances of normalized data');
    imagesc(covData);
    set(gca, 'xTick', 1:numel(dataNames), 'xTickLabel', dataNames, 'yTick', 1:numel(dataNames), 'yTickLabel', dataNames, 'yDir', 'reverse');
    colorbar;
    
    figure('numbertitle', 'off', 'name', 'R^2 of data');
    imagesc(corVals);
    set(gca, 'xTick', 1:numel(dataNames), 'xTickLabel', dataNames, 'yTick', 1:numel(dataNames), 'yTickLabel', dataNames, 'yDir', 'reverse');    
    colorbar;   
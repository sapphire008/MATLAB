function FitParms = BenWrapPolyFit(yData, timePerPoint, PolyOrder)
% fits line to data

xData = startingTime + (0:timePerPoint:(length(yData) - 1) * timePerPoint);    
FitParms = polyfit(xData, yData, PolyOrder);


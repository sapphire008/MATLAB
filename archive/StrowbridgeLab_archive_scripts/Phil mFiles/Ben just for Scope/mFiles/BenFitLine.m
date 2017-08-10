function FitParms = BenFitLine(yData, timePerPoint)
% fits line to data

xData = startingTime + (0:timePerPoint:(length(yData) - 1) * timePerPoint);    
FitParms = polyfit(xData, yData, 1);


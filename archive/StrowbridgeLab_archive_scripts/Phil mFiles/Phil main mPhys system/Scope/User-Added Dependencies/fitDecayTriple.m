function [decayTau1 decayTau2 decayTau3 FittedCurve estimates] = fitDecayTriple(yData, PSPtype)
% fits taus to ydata that is slowing in x (only determined by the initial offset)
% [decayTau1 decayTau2 decayTau3 FittedCurve estimates] = fitDecayTriple(yData, PSPtype);

if nargin == 1
   if yData(end) >  yData(1)
       PSPtype = -1;
   else
       PSPtype = 1;
   end
end

if size(yData, 1) < size(yData, 2)
    yData = yData';
end

originalLength = length(yData);                
if length(yData) > 100000
    yData(fix(length(yData)/ 500) * 500 + 1:end) = [];
    yData = mean(reshape(yData, 500, []))';
    downSampling = 500;
elseif length(yData) > 10000
    yData(fix(length(yData)/ 50) * 50 + 1:end) = [];                
    yData = mean(reshape(yData, 50, []))';
    downSampling = 50;
else
    downSampling = 1;    
end

if length(yData) < 6
    decayTau1 = NaN;
    decayTau2 = NaN;
    decayTau3 = NaN;
    FittedCurve = NaN;
    estimates = NaN;
    return
end

% generate xData
xdata = (0:length(yData) - 1)';

% Call fminsearch with a random starting point.
start_point = [yData(end) (yData(1) - yData(end)) / 2 length(yData) * -.7 (yData(1) - yData(end)) / 2 length(yData) * -.7 (yData(1) - yData(end)) / 2 length(yData) * -.7];
model = @expfun;
estimates = fminsearch(model, start_point, optimset('MaxFunEvals', 10000, 'Display', 'none'));

% check these for realism

if abs(estimates(1) - yData(end)) > abs(yData(1) / 2) ||...
        ((abs(estimates(2)) == max(abs(estimates([2 4 6]))) &&...
        (estimates(3) >= 0) || estimates(2) * PSPtype == -1) ||...
        (abs(estimates(4)) == max(abs(estimates([2 4 6]))) &&...
        (estimates(5) >= 0 || estimates(4) * PSPtype == -1)) ||...
        (abs(estimates(6)) == max(abs(estimates([2 4 6]))) &&...
        (estimates(7) >= 0 || estimates(6) * PSPtype == -1))) 
    % try shaving a few points off of the ends
   if length(yData) > 11
       [decayTau1 decayTau2 decayTau3 FittedCurve estimates] = fitDecayTriple(yData(3:end - 4), PSPtype);
       %estimates(1) = estimates(1) + xdata(2) - xdata(5);
       if isnan(decayTau1)
           return
       end
   else
       decayTau1 = NaN;
       decayTau2 = NaN;
       decayTau3 = NaN;
       FittedCurve = NaN;
       estimates = NaN;
       return
   end
else
    % return exponent with greatest magnitude
    tempDecay = abs(sort(estimates([3 5 7])));
    decayTau3 = tempDecay(1);
    decayTau2 = tempDecay(2);
    decayTau1 = tempDecay(3);
end

decayTau1 = decayTau1 * downSampling;
decayTau2 = decayTau2 * downSampling;
decayTau3 = decayTau3 * downSampling;
estimates([3 5 7]) = estimates([3 5 7]) * downSampling;

if nargout == 0
    figure, plot(xdata, yData)
    if isnan(decayTau1)
        annotation('textbox',[.25 .5 .5 .1], 'backgroundcolor', [1 1 1], 'String', 'Unable to fit', 'edgecolor', 'none', 'fontsize', 24, 'horizontalalignment', 'center', 'verticalalignment', 'middle');
    else
        line(xdata, estimates(1) + estimates(2) .* PSPtype * exp(xdata./estimates(3)) + PSPtype * estimates(4) .* exp(xdata./estimates(5)) + PSPtype * estimates(6) .* exp(xdata./estimates(7)), 'color', [1 0 0]);
        set(gcf, 'numbertitle', 'off', 'name', ['Tau1 = ' sprintf('%4.2f', decayTau1) ', Tau2 = ' sprintf('%4.2f', decayTau2)]);
    end
elseif nargout > 1
    xdata = (0:originalLength - 1)';    
    FittedCurve = estimates(1) + estimates(2) .* PSPtype * exp(xdata./estimates(3)) + PSPtype * estimates(4) .* exp(xdata./estimates(5)) + PSPtype * estimates(6) .* exp(xdata./estimates(7));
end


% expfun accepts curve parameters as inputs, and outputs sse,
% the sum of squares error for: offest + A * exp(-xdata./tau1) + B * exp(-xdata./tau2) + C * exp(-xdata./tau3) - yData
    function sse = expfun(params)
        ErrorVector = (params(1) + PSPtype * params(2) .* exp(xdata./params(3)) + PSPtype * params(4) .* exp(xdata./params(5)) + PSPtype * params(6) .* exp(xdata./params(7)))  - yData;
        sse = ErrorVector' * ErrorVector;
    end
end
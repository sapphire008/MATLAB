function [R_series, tau, rsquare] = eph_estimate_R_series_Vclamp(Is, Vs, ts, window, scalefactor, printResults)
% Return the series resistance calcualted from the capacitance current
% artifact.
% tau = C_m * R_series;
% C_m = (integrate I over t)] / V;
% 
% Inputs:
%   Is: capcitance current, need to have several milliseconds before the
%       artifact. Also assume the end of Is is at steady state [pA]
%   Vs: voltage change matching Is [mV]
%   ts: sampling rate [ms]
%   window: a window of the capcitance current artifact. The window will be
%       applied to Is and Vs to extract the capcitance current artifact.
%   printResults: printing the outputs
%
% Output:
%   R_series: series resistance in MOhm
%   tau: time constant of the capacitance current decay
%   rsquare: goodness of the fit of tau

% zData = eph_load('Neocortex B.30Aug17.S1.E22');
% ts = zData.protocol.msPerPoint;
% window = [995, 1015]; % [695, 715]; %
% Is = eph_window(zData.CurA, ts, window);
% Vs = eph_window(zData.StimulusA, ts, window);
if nargin<4 || isempty(window), window = NaN; end
if nargin<5 || isempty(scalefactor), scalefactor = 1; end
if nargin<6 || isempty(printResults), printResults = true; end
if ~isnan(window)
    Is = eph_window(Is, ts, window);
    Vs = eph_window(Vs, ts, window);
end

% Get tau of capacitance current
[~, index] = max(Is);
Is_fit = Is(index:end);
Is_fit = Is_fit - mean(Is_fit((end-5):end));
Ts_fit = 0:ts:((length(Is_fit)-1)*ts);
% Fitting the best possible
[curve_1, goodness_1] = fit(Ts_fit(:), Is_fit(:), 'a*exp(-b*x)', 'StartPoint', [max(Is_fit), 0.5]);
if goodness_1.adjrsquare >0.85
    tau = 1./abs(curve_1.b);
    rsquare = goodness_1.adjrsquare;
else
    [curve_2, goodness_2] = fit(Ts_fit(:), Is_fit(:), 'a*exp(-b*x)+c', 'StartPoint', [max(Is_fit), 0.5, min(Is_fit)]);
    if goodness_2.adjrsquare >0.85
        tau = 1./abs(curve_2.b);
        rsquare = goodness_2.adjrsquare;
    else 
        [curve_3, goodness_3] = fit(Ts_fit(:), Is_fit(:), 'a*exp(-b*x)+c*exp(-d*x)', 'StartPoint', [max(Is_fit), 0.5, min(Is_fit), 0.5]);
        tau = max(1./abs([curve_3.b, curve_3.d])); %[ms]
        rsquare = goodness_3.adjrsquare;
    end
end

% Integrate the current over the window to get total charge
Is = Is  - mean(Is((end-5):end));
Q = sum(Is(Is>0)) * ts / scalefactor; % integrate / Riemann sum the part that is above zero, i.e. the part that went to capacitance [fC]

C_m = Q / abs((Vs(end)-Vs(1))); %[pF]
R_series = tau / C_m * 1000; %[MOhm]

if printResults
    fprintf('R_series = %.4f MOhm\n', R_series);
    fprintf('tau = %.4f ms\n', tau);
    fprintf('rsquare = %.4f\n', rsquare);
end

end

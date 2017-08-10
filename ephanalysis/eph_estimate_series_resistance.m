function V_series = eph_estimate_series_resistance(Vs, baseline, mode)
% Given a trace with negative current injection Vs, 
% Return the voltage change due to series resistance.
% Vs cannot have baseline period.
%
% Inputs:
%   Vs: voltage time series
%   baseline: baseline voltage, default is the Vs(1).
%   mode: mode of operation
%       'fit': using single exponential fitting to find the voltage
%              change
%       'volt': using voltage time series directly, without fitting

if nargin<2||isempty(baseline), baseline = Vs(1); end
if nargin<3||isempty(baseline), mode = 'fit'; end
Vs = Vs(:);
G = [];
switch mode
    case 'fit'
        for n = 2:(length(Vs)-3)
            Vs0 = Vs(n:end);
            t0 = [1:length(Vs0)]';
            [F0, G0, O0] = fit(t0, Vs0, 'exp1');
            G(end+1) = G0.adjrsquare;
        end
    case 'volt'
        G = Vs;
    case 'positive'
        [Vs_min, Vs_start] = min(Vs);
        Vs = Vs(Vs_start:end);
        % fit double exponential
        %[F0, GOF] = fit((1:length(Vs))', Vs, 'exp2');
        %tau = [F0.b, F0.d];
        %[~, ind] = max(abs(tau));
        %tau = -1./tau(ind);
        xfit = (1:length(Vs)-1)';
        yfit = diff(Vs);
        xfit = xfit / range(xfit);
        yfit = yfit / range(yfit);
        [F0, GOF] = fit(xfit, yfit, 'rat11');
        f1 = @(x) x.^2 + ((F0.p1*x+F0.p2)./(F0.q1+x)).^2;
        x0 = fminbnd(f1, min(xfit), max(xfit)) - F0.q1;
        [~, x_ind] = min(abs(xfit-x0));
        V_series = Vs(x_ind)-Vs(1);
        return
    otherwise
        error('Unrecognized mode\n')
end
G_diff = abs(diff(G));
G_diff = (G_diff-min(G_diff)) / (max(G_diff)-min(G_diff)) * 100;
% Find the index between 5 to 10% improvement in fitting.
ind1 = find(G_diff<10,1);
ind2 = find(G_diff<5, 1);
ind = round(mean(ind1, ind2));
V_series = Vs(ind) - baseline;
end
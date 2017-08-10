function [dF_F, SNR, S, B, p] = ima_photometry(Xs, ts, win_signal, win_base, detrend_bool, sig_func)
% Signal to noise ratio and SNR of the photometry
% Xs: signal
% ts: sampling rate
% win_sigal: signal window (i.e. window of the light)
% win_base: baseline window
% detrend: if true, remove a linear trend from the signal. Specify multiple
%          small windows in the win_base parameter for estimating an
%          average linear trend, e.g. {[start1,end1], [start2,end2],...}
%          Note that [start1, end1] needs to be a period before any events.
% sig_func: signal function. Default mean.
% zData = eph_load('NeocortexPD C.22Nov16.S1.E25');
% Xs = zData.VoltD;
% ts = zData.protocol.msPerPoint;
% win_signal = [1000, 3000];
% win_base = {[900,1000], [8900,9000]};

if nargin<5 || isempty(detrend_bool)
    detrend_bool = true;
end
if nargin<6 || isempty(sig_func)
    sig_func = @mean;
end
S = eph_window(Xs, ts, win_signal);
if isnumeric(win_base)
    B = eph_window(Xs, ts, win_base);
elseif iscell(win_base)
    B = eph_window(Xs, ts, win_base{1});
else
    error('Unrecognized win_base type');
end

if detrend_bool
    if isnumeric(win_base)
        Trend_XY = [[win_base(1):ts:win_base(2)]', B(:)];
    elseif iscell(win_base)
        Trend_XY = [];
        for w = 1:length(win_base)
            x0 = win_base{w}(1):ts:win_base{w}(2);
            y0 = eph_window(Xs, ts, win_base{w});
            Trend_XY = [Trend_XY;[x0(:),y0(:)]];
        end
        Trend_XY = sortrows(Trend_XY);
        win_base = win_base{1};
    else
        error('Unrecognized win_base type');
    end
    p = polyfit(Trend_XY(:,1), Trend_XY(:,2), 1);
    p_func = @(x) p(1)*x;
    B = B - p_func(0:ts:diff(win_base))';% p_func(win_base(1):ts:win_base(2))';
    S = S - p_func(0:ts:diff(win_signal))';
end

dF_F = (sig_func(S) - mean(B)) / mean(B)*100;
SNR = (sig_func(S) - mean(B)) / std(B);
fprintf('maxS:%.7f\nmeanB:%.7f\nstdB:%.7f\n', max(S), mean(B),std(B));
fprintf('dFF:%.7f\nSNR:%.7f\n', dF_F, SNR);
end
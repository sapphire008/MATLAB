function Rin = eph_get_Rin(Vs, ts, neg, Ss, avg_window_size_neg, avg_window_size_base)
% Calculate Rin
if nargin<5, avg_window_size_neg = [-100,0]; end % window size to average
if nargin<6, avg_window_size_base = [-100,0]; end % window size to average

if length(neg)==3
    Rin = (min(eph_window(Vs, ts, avg_window_size_neg + neg(2))) - max(eph_window(Vs, ts, avg_window_size_base + neg(1)))) / neg(3) * 1000;
elseif length(neg)==2
    if nargin<4
        error('Specify either a trace of stimulus or the intensity of negative step in "neg" argument');
    end
    Rin = (mean(eph_window(Vs, ts, avg_window_size_neg + neg(2))) - mean(eph_window(Vs, ts, avg_window_size_base + neg(1)))) / ...
        (mean(eph_window(Ss, ts, avg_window_size_neg + neg(2))) - mean(eph_window(Ss, ts, avg_window_size_base + neg(1)))) * 1000;
else
    error('Length of "neg" argument needs to be at least 2')
end
end
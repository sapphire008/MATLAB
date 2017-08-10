function Vs = preproc_filter(Vs, ts, Wp, Ws, Rp, Rs)
% Butterworth bandpass filter between 300Hz and 3000Hz
if nargin<6 % use default if no or incomplete specification of design
    Nq = (1/ts*1000/2);
    Wp = [300, 3000]/Nq;
    Ws = [50, 4000]/Nq;
    Rp = 3; % ripple of passband [dB]
    Rs = 40; % ripple of stopband [dB]
end
[N, Wn] = buttord(Wp, Ws, Rp, Rs);
[B,A] = butter(N, Wn);
% Subtract mean
Vs_mean = mean(Vs);
Vs = Vs - Vs_mean;
% Append zeros
l = length(Vs);
pad = 2^nextpow2(l);
if (pad - l) < (0.1*l)
    pad = 2^(nextpow2(l)+1);
end
pad = pad - l;
Vs = [Vs; zeros(pad, 1)];
% Apply the filter
Vs = filtfilt(B,A, Vs);
% Recover original data
Vs = Vs(1:l) + Vs_mean;
end
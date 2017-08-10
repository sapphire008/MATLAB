function Vs = eph_filter(Vs, ts, filtertype, varargin)
% Apply a filter to Vs
% 
% Vs = eph_filter(Vs, ts, 'filtertype', ...)
%
% Inputs:
%   Vs: time series of voltage (mV)
%   ts: sampling rate (sec)
%
% Additional inputs:
%   'butter': [order, freq, low/high]
%   'smooth': [method] or [span, method] or [span, 'sgolay', degree]
%   
if nargin<3, filtertype = 'butter'; end
usedtoberow = isrow(Vs);
if usedtoberow
    Vs = Vs(:);
end
switch filtertype
    case 'butter'
        % store original data properties
        N = numel(Vs);
        Vs_mean = mean(Vs);
        % construct butterworth filter
        if isempty(varargin)
            [B,A] = butter(3,20/(1/ts/2),'low');
        else
            [B,A] = butter(varargin{:});
        end
        % zero pad the data
        Vs = [Vs-Vs_mean;zeros(2^nextpow2(N)-N,1)];
        % filter the data
        Vs = filtfilt(B,A,Vs);
        % truncate the filtered data to recover original time series
        Vs = Vs(1:N);
        % add mean back
        Vs = Vs_mean + Vs;
    case 'moving'
        Vs = smooth(Vs, varargin{:});
end

if usedtoberow
    Vs = Vs';
end
end
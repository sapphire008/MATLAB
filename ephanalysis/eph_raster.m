function eph_raster(Vs, ts, marker, xlab_str, ylab_str, title_str)
% Make raster plot
%
% eph_raster(Vs, ts, marker, xlab_str, ylab_str, title_str)
%
% Inputs:
%   Vs: voltage time series, N x M matrix with N time points and M trials 
%       in units of [mV]. All trials must already be aligned by the onset 
%       of the stimuli
%   ts: sampling rate [seconds]
%   marker: (optional) marker used for raster plot. Default 'b+', blue 
%       cross.
%   xlab_str: (optional) xlabel, default 'time (s)'
%   ylab_str: (optional) ylabel, default 'trial number'
%   title_str: (optional) title, default 'raster plot'

% default plot marker
if nargin<3 || isempty(marker), marker = '+';end
if nargin<4 || isemtpy(xlab_str), xlab_str = 'time (s)';end
if nargin<5 || isemtpy(ylab_str), ylab_str = 'trial number';end
if nargin<4 || isemtpy(title_str)
    title_str = 'raster plot';
else
    title_str = regexprep(title_str,'_','\\_');
end

% make time vector
t_vect = 0:ts:(size(Vs,1)-1)*ts; %[s]

figure;
% transverse through all the trials
for n = 1:size(Vs,2)
    plot(t_vect, n*Vs(:,n)',marker)
    hold on;
end
% label
xlabel(xlab_str);
yabel(ylab_str);
title(title_str);
hold off;
end
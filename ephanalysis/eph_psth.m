function r_hat = eph_psth(Vs, ts, delta, kernel_type)
% Calculate peri-stimulus time histogram
%
% eph_psth(Vs, ts, delta)
%
% Inputs:
%   Vs: voltage time series, N x M matrix with N time points and M trials 
%       in units of [mV].  All trials must already be aligned by the onset 
%       of the stimuli
%   ts: sampling rate [seconds]
%   delta: band width [seconds]
%   kernel_type: type of kernel: 'boxcar' (default),
%       'gaussian', and 'expoential'
%
% Output:
%   r_hat: estimated firing rate [Hz]
%
% Depends on eph_ind2time

if nargin<4 || isempty(kernel_type)
    kernel_type = 'boxcar';
end

% construct time
t_vect = eph_ind2time(1:size(Vs,1),ts);

% convolve with the kernel
f_delta = kernel_density_estimation(bsxfun(@minus,t_vect, t_vect'), ...
    kernel_type, delta);


end

function f_delta = kernel_density_estimation(t, kernel_type, delta)
switch lower(kernel_type)
    case 'boxcar'
        f_delta = zeros(1,length(t));
        f_delta(t>=-sqrt(3)*delta & t<=sqrt(3)*delta) = 1/(2*sqrt(3)*delta);
    case 'gaussian'
        f_delta = 1/(sqrt(2*pi)*delta)*exp(-t.^2/2/delta^2);
    case 'exponential'
        f_delta = 1/(sqrt(2)*delta)*exp(-sqrt(2)*abs(t/delta));
end
end
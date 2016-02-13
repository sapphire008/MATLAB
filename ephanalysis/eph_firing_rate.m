function R = eph_firing_rate(Vs, ts, method, varargin)
% Estimate a continuous, time varying firing rate
%
% R = eph_firing_rate(Vs, ts, method, ...)
%
% Inputs:
%   Vs: voltage time series, N x M matrix with N time points and M trials 
%       in units of [mV].
%   ts: sampling rate [seconds]
%   method: method of calculating firing rate of a single trial
%   
%   1). 'rect': specify a rectangular moving kernel to calculate 
%       firing rate. The default setting is (..., 'rect_kernel', 0.5), 
%       which specifies a moving kernel 500 ms.
%   2). 'gaussian': specify a Gaussian moving kernel to calculate firing
%       rate. (...,'gaussian',sigma,num_std), where sigma is the standard 
%       deviation (default 0.1s) and num_std is the number of standard 
%       deviations of Gaussian kernel to use to convolve the data 
%       (default 5).
%   If kernels are specified as a vector, each kernel will be applied to 
%   corresponding columns of Vs.
%   
% Output:
%   R: time series of the same dimension as Vs, containing calculated
%      firing rate in units of [Hz]
% 
% Depends on EPH_COUNT_SPIKES, EPH_TIME2IND, EPH_IND2TIME
%
% Implementation based on review by:
% Cunningham, J.P., Gilja, V., Ryu, S.I., Shenoy, K.V. Methods for
% Estimating Neural Firing Rates, and Their Application to Brain-Machine
% Interfaces. Neural Network. 22(9): 1235-1246 (2009).

% Detect spikes first
[~, t_spk, ~] = eph_count_spikes(Vs, ts, 'MINPEAKHEIGHT',-25);
sprintf('Detected %d spikes\n', length(t_spk));
if isnumeric(t_spk), t_spk = {t_spk}; end
t_window = [0, eph_ind2time(size(Vs,1),ts)];

% Set moving kernel
if nargin<3 || isempty(method) % set default method and kernel
    method = 'gaussian';
elseif  isempty(varargin) || isempty(varargin{1}) ||...
        ischar(varargin{1})% for specifying kernel estimation method
    % For kernel based methods, estimate kernel size
    varargin{1} = kernel_size_estimator(t_spk, varargin{1});
end

% Estimate firing rate
R = zeros(size(Vs));
for s = 1:length(t_spk)
    % Make Dirac Delta function based on spike time
    R(:,s) = eph_dirac(ts,t_window,t_spk{s},1,true);
end

% Switch between method selection of convolution functions
switch method
    case 'rect'
        w = stationary_rect_kernel(ts,varargin{:});
        methodType = 'ks'; % kernel smoothing (stationary)
    case 'gaussian'
        w = stationary_gaussian_kernel(ts, varargin{:});
        methodType = 'ks'; % kernel smoothing (stationary)
    case 'gamma'
        % Gaussian process firing rates (GPFR), spikes are drawn from Gamma
        % interval process
    otherwise
        error('Unrecognized method');
end
% Switch among types of estimators
switch methodType
    case 'ks' % kernel smoothing (stationary)
        % Convolve to get the firing rate
        if iscell(w)
            for s = 1:size(R,2)
                R(:,s) = conv(R(:,s), w{s}, 'same');
            end
        else % numeric
            R = convn(R, w, 'same');
        end
    case 'ksa' %adaptive kernel smoothing: maybe too slow. Drop
        error('This method is not implemented, concerning about speed');
end
end

%% Subroutines for each method of calculating firing rate over time
% 1). Stationary rectangular kernel
function w = stationary_rect_kernel(ts,l)
% l: width of rectangular window in seconds
% boxcar function
t = eph_time2ind(l, ts);
w = cell(1,length(l));
for n = 1:length(l)
    w{n} = ones(t(n),1);
    w{n} = [zeros(10,1); w{n}; zeros(10,1)]; % pad some arbitrary number of zeros
end
if length(w) == 1, w = w{1}; end
end

% 2). Stationary Gaussian process
function w = stationary_gaussian_kernel(ts,sigma,n)
% n: use n standard deviations below and above 0 (mean).
% sigma: standard deviation (width of Gaussian kernel).
% During Up state, sigma = 10ms according to:
% Neske, G.T., Patrick, S.L., Connor, B.W. Contributions of Diverse
% Excitatory and Inhibitory Neurons to Recurrent Network Activity in
% Cerebral Cortex. The Journal of Nueroscience. 35(3): 1089-1105 (2015).
% But this sd size may be too small for other processes. So default is set
% to 100ms for a smoother firing rate curve
% gaussian function
if nargin<2 || isempty(sigma), sigma = 100/1000; end
if nargin<3 || isempty(n), n = 5; end
w = cell(1,length(sigma));
for k = 1:length(sigma)
    t = (-n*sigma(k)):ts:(n * sigma(k));
    w{k} = 1/(sqrt(2*pi)*sigma(k))*exp(-t.^2/(2*sigma(k)^2))';
end
if length(w) == 1, w = w{1}; end
end

function k = kernel_size_estimator(t_spk, method, varargin)
switch lower(method)
    case 'isi'
        % Based on / similar to Kernel Bandwidth Optimization (KBO)
        % Assume Poisson distribution of spiking
        k = cellfun(@diff, t_spk, 'un',0);
        k= 5 * cellfun(@mean, k);
        % the factor 5 above: include at least 5 spikes in average
    case 'poisson'
        % based on Shimazaki, H. and Shinomoto, S. Kernel bandwidth
        % optimization in spike rate estimation. J. Comput. Neurosci.
        % 29(1-2): 171-182. (2010)
        % varargin = {'kernel function', t_window_vect}
        % e.g. {'gaussian',[0, 0.01, 0.02, ..., 1]}
        k_w_t = @(w, t) 1/(sqrt(2*pi)*w)*exp(-t.^2/(2*w^2)); % gaussian
        t_window_vect = varargin{2};
        N = numel(t_spk);
        psi_w_ti_tj = @(w, ti, tj) k_w_t(w, t_window_vect-ti)*k_w_t(w, t_window_vect-ti)';
        psi_w = @(w) rapply(@(x) psi_w_ti_tj(w, x(1), x(2)), nchoosek(sigma));
        C_w = @(w) 1/N^2*sum(psi(:)) - 2/N^2;
end
end

function out = rapply(fhandle, mat, varargin)
% apply a function across row
out = cell(1,size(mat,1));
flag.uniformoutput = 0;
sind = 1:2:length(varargin);
optind = sind(strncmpi(varargin(sind), 'un', 2));
if ~isempty(optind)
    flag.uniformoutput = varargin{optind+1};
end
for n = 1:length(out)
    out{n} = fhandle(mat(n,:));
end
if flag.uniformoutput
    out = cell2mat(out);
end
end


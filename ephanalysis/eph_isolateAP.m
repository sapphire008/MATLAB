function [AP_time, thresh, fAHP, AP_height, max_rising, APs, fAHP_time, AP_width, AP_half_width] = ...
    eph_isolateAP(Vs, ts, kernel, numap2get, rising_thresh, varargin)
% Isolate action potentials from a time series of voltage trace. Summarize
% the properties of these action potentials
%
% [AP_time, thresh, fAHP, AP_height, max_rising, APs, fAHP_time] = eph_count_fAHP(Vs, ts, kernel, option1, var1 ...)
%
% Inputs:
%   Vs: voltage time series, N x 1 matrix with N time points in units of [mV].
%   ts: sampling rate [seconds]
%   kernel: kernel size for calculating max_rising
%   num2get: number of APs to calculate the properties for. Default all
%           detected APs.
%   rising_thresh: How many percent of the max_rising shall the AP 
%               threshhold need to pass? By default, the threshold of the 
%               AP is at 10% of the max_rising.
%   
% 
% Outputs:
%   AP_time: time of each AP
%   thresh: threshold of each AP
%   fAHP: fast AHP following each AP
%   AP_height: height of the AP from threshold
%   max_rising: maximum speed of rising of AP
%   APs: isolated single AP traces, return as a cell array
%   fAHP:time: time of the fAHP detected
%
%   Optional criteria to select spikes, following arguments of FINDPEAKS 
%   function. Relevant options include the following: 
%           'MINPEAKHEIGHT', MPH: spikes need to be above MPH
%           'MINPEAKDISTANCE, MPD: neighboring spikes need to be MPD apart.
%                            Note that this is in seconds, instead of
%                            number of indices for FINDPEAKS.
%           'THRESHOLD', TH: inds peaks that are at least greater than 
%                            their neighbors by the THRESHOLD TH.
%           'NPEAKS', NP: maximum number of peaks to find
%
%   Default: {'MINPEAKHEIGHT', -10}
%
% Depends on EPH_IND2TIME,EPH_TIME2IND, EPH_COUNT_SPIKES

if nargin<3 || isempty(kernel), kernel = 5*ts;end
if nargin<4 || isempty(numap2get), numap2get=NaN; end
if nargin<5 || isempty(rising_thresh), rising_thresh = 0.1; end

if all(isnan(Vs)) || length(Vs)<2
    error('Invalid voltage trace input Vs');
end

try % see if can detect any APs at all
    [numAP, AP_time, ~] = eph_count_spikes(Vs, ts, varargin{:});
    ind = eph_time2ind(AP_time, ts);
catch
    [AP_time, thresh, fAHP, AP_height, max_rising, APs] = tuple(NaN);
    return
end
if numAP < 1
    [AP_time, thresh, fAHP, AP_height, max_rising, APs] = tuple(NaN);
    return
end
%%
[thresh, fAHP, fAHP_ind, AP_height, max_rising, AP_width, AP_half_width] = tuple(NaN(1,length(ind)));
APs = cell(1,length(ind));
APs_time_segment = cell(1,length(ind));
% Identify each fAHP first
for k = 1:length(ind)
    % fAHP
    if k<length(ind)
        [fAHP(k), fAHP_ind(k)] = min(Vs(ind(k):ind(k+1)));
        fAHP_ind(k) = fAHP_ind(k) + ind(k)-1;
    end
end
% last fAHP
[fAHP(end), fAHP_ind(end)] = min(Vs(ind(end):end));
fAHP_range = [-1.5, 1.5] * nanstd(fAHP) + nanmean(fAHP);
if fAHP(end)<0 && fAHP(end)<=max(fAHP_range) && fAHP(end)>=min(fAHP_range)
    fAHP_ind(end) = fAHP_ind(end) + ind(end)-1;
else
    fAHP_ind(end) = NaN;
    fAHP(end) = NaN;
end
% close; plot(Vs); hold on; plot(fAHP_ind, fAHP, 'ro');
fAHP_time = eph_ind2time(fAHP_ind, ts);
% Segment each APs
AP_ind = [1, fAHP_ind];
for i = 1:length(fAHP_ind)
    if isnan(fAHP_ind(i))
        continue;
    end
    APs{i} = Vs(AP_ind(i):AP_ind(i+1));
    APs_time_segment{i} = eph_ind2time(AP_ind(i):AP_ind(i+1), ts);
    %hold on; plot(AP_ind(i):AP_ind(i+1), APs{i})
end
if isnan(fAHP_ind(end)) && fAHP_ind(end-1)<ind(end)
    % must have an additional spike
    APs{end} = Vs(fAHP_ind(end-1):end);
    APs_time_segment{end} = eph_ind2time(fAHP_ind(end-1):length(Vs),ts);
end
% Find properties of each AP
kern = ceil(kernel/ts)-1;
if isnan(numap2get)
    numap2get = length(APs);
end
for k = 1:numap2get
    AP = APs{k};
    AP_start = find(AP>min(fAHP_range),1);
    AP = AP(AP_start:end);
    dAP = zeros(1, length(AP)-kern);
    % slopes of the AP
    for m = 1:length(dAP)
        dt0 = m:m+kern;
        dAP0 = AP(dt0);
        %plot(dt0, dAP0);
        dt0 = dt0*ts-ts;
        dt0 = [dt0(:),ones(length(dt0),1)];
        s = dt0\dAP0(:);
        dAP(m) = s(1);
    end
    % find max_rate
    [max_rising(k), max_rising_time] = max(dAP);
    thresh_thresh = rising_thresh * max_rising(k);
    
    [~, thresh_ind] = min(abs(dAP(1:max_rising_time) - thresh_thresh));
    thresh(k) = AP(thresh_ind);
    %plot(thresh_ind, thresh, 'bo');
    AP_height(k) = max(AP) - thresh(k);
    % AP width from the threshold
    [~, AP_height_ind] = max(AP);
    [~, AP_width_ind] = min(abs(AP(AP_height_ind:end) - thresh(k)));
    AP_width(k) = (AP_width_ind + AP_height_ind - thresh_ind) * ts;
    % AP half width
    [~, AP_half_width_ind_1] = min(abs(AP(1:AP_height_ind) - (AP_height(k)/2 + thresh(k))));
    [~, AP_half_width_ind_2] = min(abs(AP(AP_height_ind:end) - (AP_height(k)/2 + thresh(k))));
    AP_half_width(k) = (AP_half_width_ind_2 + AP_height_ind - AP_half_width_ind_1) * ts;
end

% close;
% plot(0:ts:(length(Vs)-1)*ts,Vs);
% hold on;
% plot(fAHP_time, fAHP, 'ro');

end

function varargout = tuple(varargin)
% allows simultaneous assignment
% [a,b,c] = tuple(x,y,z);
if nargin == nargout
    varargout = varargin;
elseif nargin==1
    for k = 1:nargout
        varargout{k} = varargin{1};
    end
else
    error('Unbalanced number of input and output arguments')
end
end
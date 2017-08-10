function [num_spikes, spike_time, spike_heights] = eph_detect_cell_attached_spikes(Is, ts, varargin)
% Detect cell attached extracellular spikes
% [num_spikes, spike_time, spike_heights] = eph_detect_cell_attached_spikes(Is, ts, option1, val1, ...)
% Inputs:
%   Is: Current time series, N x 1 vector with N time points in pA.
%   ts: sampling rate [seconds]
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
%           'BASEFILT': baseline medfilt1 filter order in unit of ts
%           'REMOVEBASE': remove baseline when returning height. This will
%                         reults absolute height of spike relative to the 
%                         baseline. If set to false, returning the value of
%                         the spike, before filtering.
%           'MAXPEAKHEIGHT': maximum spike height.
%
%   Default: {'MINPEAKHEIGHT', 30}, {'MINPEAKDISTANCE', 10}, {'BASEFILT',20}
%            {'REMOVEBASE', true}, {'MAXPEAKHEIGHT',300}
% Outputs:
%   num_spikes: number of spikes
%   spike_time: indices of the spike, returned as a vector
%   spike_heights: Current of the spike [pA], returned as a vector
%
% Depends on EPH_IND2TIME, FINDPEAKS

%zData = eph_load('NeocortexCA H.14Dec15.S1.E15');
%Is = zData.CurA; ts = zData.protocol.msPerPoint;
flag_fp = parse_varargin(varargin, {'MINPEAKHEIGHT', 30}, {'MINPEAKDISTANCE',10});
flag_other = parse_varargin(varargin, {'REMOVEBASE',true}, {'BASEFILT', 20}, {'MAXPEAKHEIGHT', 300});
flag_fp.MINPEAKDISTANCE = flag_fp.MINPEAKDISTANCE/ts;
flag_fp = structcellitems(flag_fp);
% Median filter out the spikes to get a baseline
Base = medfilt1(Is, flag_other.BASEFILT/ts); % 20 ms
Is = Is - Base;
[PKS, LOCS] = findpeaks(-Is, flag_fp{:});
num_spikes = length(PKS);
spike_time = eph_ind2time(LOCS, ts);
% Remove peaks exceeding max height
ind = find(PKS<flag_other.MAXPEAKHEIGHT);
LOCS = LOCS(ind);
PKS = PKS(ind);
% if remove base
if flag_other.REMOVEBASE
    spike_heights = PKS;
else
    spike_heights = -PKS + Base(LOCS);
end
% close;
% plot(-Is);
% hold on;
% plot(LOCS, PKS, 'ro');
% hold off;
end

function C = structcellitems(S)
FIELDS = fieldnames(S);
C = cell(2, length(FIELDS));
for f = 1:length(FIELDS)
    C{1, f} = FIELDS{f};
    C{2, f} = S.(FIELDS{f});
end
C = C(:);
C = C';
end

function flag = parse_varargin(options, varargin)
% Search for options specified in 'options'.
% input as triplet cellstrs, {'opt1','default1'}.
% return flag with fields 'opt1', 'opt2', ...

flag = struct();%place holding
for n = 1:numel(varargin)
    % search if a certain option is present in the specification
    tmp = ismember(options(1:2:end),varargin{n}{1});
    if any(tmp) % if present, assign using input value
        flag.(varargin{n}{1}) = options{2*find(tmp,1)};
    else % if not present, assign default value
        flag.(varargin{n}{1}) = varargin{n}{2};
    end
    clear tmp;
end
end
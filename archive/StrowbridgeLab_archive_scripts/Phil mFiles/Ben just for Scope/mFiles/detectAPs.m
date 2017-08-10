function APtimes=detectAPs(data,protocol,varargin)
%  Ben routine to find APs in current clamp record
%   Inputs  data, protocol, (AP threshold in mV), ([beginTimeMs, endTimeMs])
%   Output is a list of AP times in ms or []
% this routine takes one current clamp record and returns the times of each
% AP in trace
APtimes=[];
if nargin<1
    return;
end
if nargin>2
    APthreshold=varargin{1};
else
    APthreshold=-30; % default in mV
end
if nargin>3
    tempWindow=varargin{2};
    beginTime=tempWindow(1);
    endTime=tempWindow(2);
else
    beginTime=0;
    endTime=protocol.sweepWindow;
end

pointsPerMs=1/(protocol.timePerPoint/1000);
beginIndex=(beginTime*pointsPerMs)+1;
endIndex=endTime*pointsPerMs;
resetPoints=1*pointsPerMs; % wait at least 1 ms after trip up threshold to enable another spike to be detected

set=0;
reset=0;
resetThreshold=APthreshold-10; % make down threshold 10 mV more hyperpol than up threshold
APindex=[];
for i=beginIndex:endIndex
    if set==1
        % already past an up threshold so now look for potentials below
        % lower reset threshold
        if data(i)<resetThreshold
            reset=reset+1;
            if reset>resetPoints
                % gone for enough down points so re-enable detection
                set=0;
                reset=0;
            end
        end
    else
        % not immediately after a detected event because set==0
        if data(i)>APthreshold
            % found a spike so mark time
            APindex=[APindex i];
            set=1;
        end
    end
end
APtimes=APindex.*(protocol.timePerPoint/1000);

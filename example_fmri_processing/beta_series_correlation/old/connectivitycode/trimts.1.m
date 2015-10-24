function [y,ntrimmed] = trimts(y,sd,X,varargin)
% function [y,ntrimmed] = trimts(y,sd,X,[do spike correct])
% 1.  Adjusts for scan effects (unless X is empty)
% 2.  Windsorizes timeseries to sd standard deviations
%       - Recursive: 3 steps
% 3.  Adds scan effects back into timeseries
% Tor Wager

% filter y using X matrix; yf is residuals

if ~isempty(X),
    mfit = X * pinv(X) * y;
    yf = y - mfit;
else
    yf = y;
end

if length(varargin) > 0
    
    
    % attempt to correct for session-to-session baseline diffs
    
    tmp = diff(yf);
    mad12 = median(abs(tmp)) * Inf;    % robust est of change with time (dt)
    wh = find(abs(tmp) > mad12);
    n = 20;
    
    for i = 1:length(wh), 
        st = max(wh(i) - (n-1),1);  % start value for avg
        en = max(wh(i),1);
        st2 = wh(i)+1;
        en2 = min(wh(i)+n,length(yf));  % end value for after
        wh2 = st2:en2;
        m = mean(yf(wh(i)+1:en2)) - mean(yf(st:en)); % average of 5 tp after -  5 time points before
        %figure;plot(st:en2,yf(st:en2));
        yf(wh(i)+1:end) = yf(wh(i)+1:end) - m;,
    end
    
    
    % do spike correction!  Interpolate values linearly with 1 nearest
    % neighbor
    %
    % replace first val with mean
    n = min(length(yf),50);
    yf(1) = mean(yf(1:n));
    
    tmp = diff(yf);
    mad5 = median(abs(tmp)) * 5;    % robust est of tail of dist. of change with time (dt)
    wh = find(abs(tmp) > mad5);
    
    % find paired changes that are w/i 3 scans
    whd = diff(wh);
    wh = wh(whd < 3);
    whd = whd(whd < 3);

    % value of spike is avg of pre-spike and post-spike val.
    wh(wh == 1 | wh == length(yf)) = [];
    for i = 1:length(wh)-1   % bug fix, CW
        yf(wh(i)+1) = mean([yf(wh(i)) yf(wh(i)+1+whd(i))]);
    end
    

end
    
    
    
% trim residuals to sd standard deviations
% "Windsorize"

my = mean(yf);
%sy = std(yf);

%w = find(yf > my + sd * sy);
%w2 = find(yf < my - sd * sy);

%yf(w) = my + sd * sy; 	%NaN;
%yf(w2) = my - sd * sy;

allw = [];

for i = 1:3
    yf2 = scale(yf);
    w = find(abs(yf2) > sd);
    yf(w) = mean(yf) + sd * std(yf) * sign(yf(w));
    
    allw = [allw; w];
end

% put means back into yf
if ~isempty(X),
    y = yf + mfit;
else
    y = yf;
end

ntrimmed = length(unique(allw));  % w) + length(w2);

return
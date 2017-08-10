function Vs = eph_detrending(Vs, ts, mode)
% Detrending data
% mode: 
%   'mean': remove mean
%   'linear' (Deafult),'nearest', 'zero', 'slinear', 'quadratic', 'cubic': using interp1d
%   'polyN': fit a polynomial for Nth degree. e.g. 'poly3' fits a cubic curve
% Do not mistake 'linear' mode as removing a global linear trend. For removing global linear trend,
% use 'poly1' instead

if strcmpi(mode,'mean')
    y_hat = mean(Vs);
else
    x = 0:ts:eph_ind2time(length(Vs), ts);
    if any(strcmpi(mode, {'linear','nearest','next','previous','spline','pchip', 'cubic','v5cubic'})) %splines
        y_hat = interp1(x, Vs, x, mode);
    elseif strncmpi(mode, 'polyN', 4)
        n = str2num(mode(5:end));
        p = polyfit(x, Vs, n);
        y_hat = polyval(p, x);
    end
end

Vs = Vs - y_hat;
end
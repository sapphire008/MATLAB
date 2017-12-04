function [f0, gof, p0] = eph_fitExp(T, X, p0)
T = T(:);
X = X(:);

if nargin<3 || isempty(p0)
    % Estimate a tau
    rms = @(x) sqrt(mean((x.^2)));

    if X(end)<X(1) % falling
        p0 = [max(X) - min(X), 0, 0];
        index = find(abs(X - (1/exp(1) * (X(1)-X(end)) + X(end))) < 0.1 * rms(X), 1);
        p0(2) = -1./T(index);
    else % rising
        p0 = [min(X) - max(X),0,0];
        index = find(abs(X - ((1-1/exp(1)) * (X(end)-X(1)) + X(1))) < 0.1 * rms(X), 1);
        p0(2) = 1./T(index);
    end
end
[f0, gof] = fit(T, X, 'a*exp(-b*x)+c', 'StartPoint', p0);
end

function s = statrobustsigma(wfun,r,p,s,t,h)

% Include tuning constant in sigma value
st = s*t;

% Get standardized residuals
n = length(r);
u = r ./ st;

% Compute derivative of phi function
phi = u .* feval(wfun,u);
delta = 0.0001;
u1 = u - delta;
phi0 = u1 .* feval(wfun,u1);
u1 = u + delta;
phi1 = u1 .* feval(wfun,u1);
dphi = (phi1 - phi0) ./ (2*delta);

% Compute means of dphi and phi^2; called a and b by Street.  Note that we
% are including the leverage value here as recommended by O'Brien.
m1 = mean(dphi);
m2 = sum((1-h).*phi.^2)/(n-p);

% Compute factor that is called K by Huber and O'Brien, and lambda by
% Street.  Note that O'Brien uses a different expression, but we are using
% the expression that both other sources use.
K = 1 + (p/n) * (1-m1) / m1;

% Compute final sigma estimate.  Note that Street uses sqrt(K) in place of
% K, and that some Huber expressions do not show the st term here.
s = K*sqrt(m2) * st /(m1);

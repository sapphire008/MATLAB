% different classes solvers for W = [a,b,c,d]
function [W, DIAGNOSTICS] = wSolver(x, y, u, solve_method, W0, show_diagnostics)
if nargin<6 || isempty(show_diagnostics), show_diagnostics = false; end
DIAGNOSTICS = [];
switch solve_method
    case 'fsolve'
        % solve non-linear systems of equations: trust-region dogleg, but
        % cannot handle non-square case; use levenberg-marquardt instead.
        fh = @(W) wEstimator(W, x, y, u);
        if numel(u) ~= numel(W0)
            options = optimoptions('fsolve','Display','off', ...
                'Algorithm','levenberg-marquardt',...
                'ScaleProblem','Jacobian','TolFun',1E-12,'TolX',1E-12);
        else
            options = optimoptions('fsolve','Display','off', ...
                'Algorithm','trust-region-dogleg','TolFun',1E-12,...
                'TolX',1E-12);
        end
        [W, fval, exitflag, output, jacobian] = fsolve(fh, W0, options);
        if show_diagnostics
            DIAGNOSTICS = struct('fval',fval,'exitflag',exitflag,'output',output, 'jacobian',jacobian);
        end
    case 'lsq'
        % specialized to minimize sum squares of system of functions
        fh = @(W) wEstimator(W, x, y, u);
        options = optimoptions('lsqnonlin','Display','off',...
            'Algorithm','levenberg-marquardt','ScaleProblem','Jacobian',...
            'TolFun',1E-12,'TolX',1E-12);
        [W,resnorm,residual,exitflag,output,lambda,jacobian] = lsqnonlin(fh, W0, [], [], options);
        if show_diagnostics
            DIAGNOSTICS = struct('resnorm',resnorm,'residual',residual,'exitflag',exitflag,'output',output,'lambda',lambda,'jacobian',jacobian);
        end
    case 'fminsearch'
        fh = @(W) sum(wEstimator(W,  x, y, u).^2);
        options = optimset('Display','off');
        [W, fval, exitflag, output] = fminsearch(fh, W0, options);
        if show_diagnostics
            DIAGNOSTICS = struct('fval',fval,'exitflag',exitflag,...
                'output',output,'TolFun',1E-12,'TolX',1E-12);
        end
    case 'fminunc'
        fh = @(W) sum(wEstimator(W,  x, y, u).^2);
        options = optimoptions('fminunc','Display','off', ...
            'Algorithm','quasi-newton','TolFun',1E-12,'TolX',1E-12);
        [W, fval, exitflag, output, grad, hessian] = fminunc(fh, W0, options);
        if show_diagnostics
            DIAGNOSTICS = struct('fval',fval,'exitflag',exitflag,'output',output,'grad',grad,'hessian',hessian);
        end
end
end

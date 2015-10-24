%% Solvers and Estimator
% different classes solvers for S = [p, q, r]
function [S, DIAGNOSTICS] = sSolver(x, y, u, solve_method, S0, show_diagnostics)
if nargin<6 || isempty(show_diagnostics), show_diagnostics = false; end
DIAGNOSTICS = [];
switch solve_method
%    case 'fsolve'
%         % solve non-linear systems of equations: trust-region dogleg, but
%         % cannot handle non-square case; use levenberg-marquardt instead.
%         fh = @(S) sEstimator(S, x, y, u);
%         if numel(u) ~= numel(S0)
%             options = optimoptions('fsolve','Display','off', ...
%                 'Algorithm','levenberg-marquardt',...
%                 'ScaleProblem','Jacobian','TolFun',1E-12,'TolX',1E-12);
%         else
%             options = optimoptions('fsolve','Display','off', ...
%                 'Algorithm','trust-region-dogleg','TolFun',1E-12,...
%                 'TolX',1E-12);
%         end
%         [S, fval, exitflag, output, jacobian] = fsolve(fh, S0, options);
%         if show_diagnostics
%             DIAGNOSTICS = struct('fval',fval,'exitflag',exitflag,'output',output, 'jacobian',jacobian);
%         end
    case 'lsq'
        % specialized to minimize sum squares of system of functions
        fh = @(S) sEstimator(S, x, y, u);
        options = optimoptions('lsqnonlin','Display','off',...
            'Algorithm','levenberg-marquardt','ScaleProblem','Jacobian',...
            'TolFun',1E-12,'TolX',1E-12);
        [S,resnorm,residual,exitflag,output,lambda,jacobian] = lsqnonlin(fh, S0, [0,-Inf,0], [], options);
        if show_diagnostics
            DIAGNOSTICS = struct('resnorm',resnorm,'residual',residual,'exitflag',exitflag,'output',output,'lambda',lambda,'jacobian',jacobian);
        end
%     case 'fminsearch'
%         fh = @(S) sum(sEstimator(S,  x, y, u).^2);
%         options = optimset('Display','off');
%         [S, fval, exitflag, output] = fminsearch(fh, S0, options);
%         if show_diagnostics
%             DIAGNOSTICS = struct('fval',fval,'exitflag',exitflag,...
%                 'output',output,'TolFun',1E-12,'TolX',1E-12);
%         end
    case 'fmincon'
        fh = @(S) sum(sEstimator(S, x, y, u).^2);
        options = optimoptions('fmincon','Display','off', ...
            'Algorithm','sqp','TolFun',1E-12,'TolX',1E-12,...
            'TolCon',1E-12,'Scaleproblem','obj-and-constr', 'GradConstr','on');
        [S, fval, exitflag, output, lambda, grad, hessian] = fmincon(fh, S0, [-1,0,-1], 0, [], [], [], [], @sConstraints, options);
        if show_diagnostics
            DIAGNOSTICS = struct('fval',fval,'exitflag',exitflag,'output',output,'lambda',lambda,'grad',grad,'hessian',hessian);
        end
end
end

% S estimator
function f = sEstimator(S, x, y, u) % S = [p, r, q]
f = bsxfun(@minus,S(1)*x.^2 + S(3)*y.^2+S(2)*2*x.*y,u);
f = f(:); f = f(isfinite(f));
end

% constraint function: S = [p, r, q]; c(S)<=0
function[c, ceq, gradc, gradceq] = sConstraints(S)
c = S(2)^2 - S(1) * S(3); %r^2-p*q<=0
ceq = [];
if nargout>2
    gradc = [-S(3), -S(1), 2*S(2)]';
    gradceq = [];
end
end
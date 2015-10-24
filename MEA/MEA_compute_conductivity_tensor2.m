function [Sigma, S, DIAGNOSTICS, SUMMARY] = MEA_compute_conductivity_tensor2(U,J,PITCH,XY_J,MAP,varargin)
% Compute conductivity tensor map based on a map of voltage U and transient
% current source I injected at location (x,y). Solve by directly estimating
% the inverse of Sigma.
%
% [Sigma, S, DIAGNOSTICS, SUMMARY] = MEA_compute_conductivity_tensor(
%                                       U, I, MAP, XY_I, 'opt1', val1, ...)
%
% Inputs:
%   U: MxN matrix specifies voltage at M electrodes and N stimulations, in
%      units of mV
%   J: current source vector (uA), assuming the current is a transient 
%      pulse. Length must match that of the second dimension of U.
%   PITCH: the actual distance of 1 unit represented on the MAP, in mm.
%   XY_J: coordinate of transient current injection
%   MAP: list of coordinates correponding to the points in the first 
%        dimension of U. Each row is a point
%
% Optional Parameters:
%   'method': method of optimization to solve whitening matrix W (see
%             Algorithm below). Methods available are:
%               ~ fminunc: minimizing sum square of F_ij
%               ~ fminsearch: minimizing sum square of F_ij
%               ~ lsq: lsqnonlin in MATLAB, minimizing sum square of F_ij
%               ~ fsolve: solving system of equations of F_ij
%   'S0': initial value for optimization. Specify as a Kx4 matrix. 
%         Default is 999 normally distributed random sets, plus the 
%         identity matrix. This will usually yield 1000 total starting 
%         matrices.
%   'NN': up to NNth nearest neighbors to include in the optimization.
%         Default 2.
%   
% Output:
%   Sigma: conductivity tensor at specified point XY_I, concatenated over
%          all the testing initial values in the 3rd dimension, with 
%          outliers have been removed, based on non-parametric statistics
%          proposed by R's boxplot.stats; each having the form:
%               [s_xx, s_yx; 
%                s_xy, s_yy]
%          
%   S: Inverse of Sigma that contains the solution of optimization 
%      [p, q, r]; see 'Algorithm' section.
%
%   DIAGNOSTICS: cell array of structures that contains different
%                diganostic parameters output by each optimization
%                algorithms
%
%   SUMMARY: structure that contains summary of results, including all the
%            optional parameter values ('method','diagnostics', etc...) as
%            well as diagnostic figure handles and most likely results of W
%            and Sigma based on minimized values.
%
%
% -----------------------------------------------------------------------
%                       >>>>> Algorithm <<<<<
% Whitening matrix W:
% W = [a,b;
%      c,d]
% SIGMA = inv(W*W')
%(J/(4*pi*U(x,y)))^2 = (a^2+c^2)*x^2 + (b^2+d^2)*y^2+(a*b+c*d)*2*x*y;
% To estimate W, optimize a,b,c,d so that
% (a^2+c^2)*x_i^2 + (b^2+d^2)*y_i^2+(a*b+c*d)*2*x_i*y_i -
% (J_j/(4*pi*U(x_i,y_i)))^2 = 0, for each i and j.
% Let p = a^2+c^2, q = b^2+d^2, r = a*b+c*d. Then, let 
% S = W*W' = [p, r;
%             r, q]
% The problem becomes
% (J_j/(4*pi*U(x_i,y_i)))^2 - (p*x_i^2 + q*y_i^2+ r*2*x_i*y_i), with
% constraints p*q-r^2>0 and p+q>0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%Debug
% varargin = {};
%% Parse Basic Info
SUMMARY = parse_varargin(varargin,{'method','fmincon'},{'NN',2},...
    {'S0',set_default_test_S0(1000,'randn')},...
    {'diagnostics',true}, {'channelnames', []});
% find nearest neighbor
[XY_NN,IND,Nth] = find_nearest_neighbor(MAP,XY_J,SUMMARY.NN);
% find index of current channel
[~,IA,~] = intersect(MAP,XY_J,'rows','stable');
% center the specified electrode
XY_NN = bsxfun(@minus,XY_NN,XY_J)*PITCH;
% find voltage of these nearest neighbors
U = U(IND,:); 
% sort U's columns by I
[J,J_IND] = sort(J); U = U(:,J_IND);
% find channel names of current channel and nearest neighbors
if ~isempty(SUMMARY.channelnames)
    current_channel = SUMMARY.channelnames{IA};
    nn_channel = SUMMARY.channelnames(IND);
else
    current_channel = []; nn_channel = [];
end
% Summary and diagnostics
DIAGNOSTICS = cell(1,size(SUMMARY.S0,1));
SUMMARY.nearest_neighbor_properties = struct('count',size(XY_NN,1),...
    'coord', XY_NN, 'ind',IND,'nth',Nth);
%% Estimate I/U Calculating Tensor
if size(U,2)>1 && numel(unique(J))>1
    % estimate conductance given different stimulation
    V = (estimate_conductance(U,J,SUMMARY.diagnostics,Nth,...
        current_channel,nn_channel)/(4*pi)).^2;
else
    % find left hand side of the equation: inaccurate!!
    warning('results may be inaccurate!');
    V = bsxfun(@rdivide, J(:)',4*pi*U).^2;
end
%% Estimate S
% construct system of equations and solve S = [p, r, q];
S = zeros(size(SUMMARY.S0));
for n = 1:size(SUMMARY.S0,1)
    [S(n,:), DIAGNOSTICS{n}] = sSolver(XY_NN(:,1), XY_NN(:,2), V, ...
        SUMMARY.method, SUMMARY.S0(n,:),SUMMARY.diagnostics);
    %disp(DIAGNOSTICS{n}.output.iterations);%debug
end
%% Calculate Tensor
S = [S(:,1:2),S(:,2:3)];
S = reshape(S',2,2,size(S,1));
Sigma = zeros(size(S));
for m = 1:size(S,3)
    if rcond(S(:,:,m))<1E-15 % singular
        Sigma(:,:,m) = NaN; % remove singular cases
    else
        Sigma(:,:,m) = inv(S(:,:,m)); 
    end
end
% remove NaN
NotNaN_IND = find(~isnan(Sigma(1,1,:)));
Sigma = Sigma(:,:,NotNaN_IND);
S = S(:,:,NotNaN_IND);
DIAGNOSTICS = DIAGNOSTICS(NotNaN_IND);
% remove outliers
[Sigma, Sigma_IND] = remove_outlier_Rboxplot(Sigma,3);
S = S(:,:,Sigma_IND);
DIAGNOSTICS = DIAGNOSTICS(Sigma_IND);
% calculate more diagnostics and plot distributions
if SUMMARY.diagnostics
   SUMMARY = diagnose_S_Sigma(SUMMARY, DIAGNOSTICS, S, Sigma, 50);
   %fprintf('fval = %.3f\n',SUMMARY.fvals);
end
end

%% Set initial S0
function S0 = set_default_test_S0(N, set_method)
if nargin<2 || isempty(set_method), set_method = 'randn'; end
S0 = [1,0,0,1]; %[p, r, r, q]
numgen = round((N-1)/2);
% add more randomly generated S0's;
while size(S0,1)<N
    switch set_method
        case 'randn'
            tmp = [abs(randn(numgen,1)),randn(numgen,1),abs(randn(numgen,1))];
        case 'rand'
            tmp = [rand(numgen,1);randn(numgen,1)-0.5;randn(numgen,1)];
    end
    tmp = [tmp(:,1:2),tmp(:,2:3)];
    tmp = reshape(tmp',2,2,size(tmp,1));
    K = false(1,size(tmp,3));
    for k = 1:size(tmp,3)
        % non-singular, positive
        K(k) = rcond(squeeze(tmp(:,:,k)))<1E-10 | ...
            det(squeeze(tmp(:,:,k)))<0;
    end
    tmp = tmp(:,:, find(~K));
    S0 = [S0; reshape(tmp, 4,size(tmp,3))'];
    S0 = unique(S0,'rows','stable');
    if size(S0,1)>N, S0 = S0(1:N,:); end
end
S0 = S0(:,[1,2,4]);
end

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
        [S, fval, exitflag, output, lambda, grad, hessian] = fmincon(fh, S0, [], [], [], [], [0,-Inf,0], [Inf,Inf,Inf], @sConstraints, options);
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

% Use for S estimator correction
function [G, I0] = estimate_conductance(U,J,show_diagnostics, Nth, current_channel, NN_channels)
% Estimate conductivity and leaky current, given measured voltage and
% different current sources / stimuli
%
% Inputs:
%   U: NxM matrix, with N locations/observations, and M current intensities
%   I: 1xM vector, with M current intensities
% Outputs:
%   G: conductance of each locations. Note that unit is I/U.
%   I0: leaky current, same unit as I.
%
% The function will fit a straight line between current and observed
% voltage. The reciprocal of the slope of the fit will be the conductance,
% whereas the intercept will be the leaky current (values of I when U = 0)
%

% Fit the line
P = cell2mat(cellfun(@(x) polyfit(J,x,1),...
    mat2cell(U,ones(1,size(U,1)),size(U,2)),'un',0));
G = 1./P(:,1);
I0 = -P(:,2)./P(:,1);
% plot diagnostics
if ~show_diagnostics, return; end
marker_list = {'bo','ro','go','ko','mo','b*','r*','g*','k*','m*',...
    'b.','r.','g.','k.','m.'};
% Do statistical test
% do anova on ratio J/U
[U_J_diag.aov_p, U_J_diag.aov_table, ...
    U_J_diag.aov_stats] = anova1(bsxfun(@rdivide,J,4*pi*U)'.^2,[],'on');
if nargin<4 || isempty(Nth), Nth = 1:length(G); end
set(gca,'XTickMode','auto','XTickLabelMode','manual','XTickLabel',cellstr(num2str(Nth)));
axis2 = get(gca,'children');
% Copy figures
h = gcf-1;
close(h); figure(h);
h2 = subplot(2,2,[1,2]);
copyobj(axis2,h2);
set(gca,'XTickMode','auto','XTickLabelMode','manual','XTickLabel',cellstr(num2str(Nth)));
xlabel('Neighbors');
ylabel('(J_k/4\piU)^2');
title(['ANOVA p=',num2str(U_J_diag.aov_p)]);
close(h+1);
if nargin<5 || ~isempty(current_channel), current_channel = '';end
suptitle([current_channel,' Voltage vs. Current Diagnostics']);
% plot I/V across all neighboring electrodes
m = [repmat(marker_list,1,floor(size(U,2)/numel(marker_list))),...
    marker_list(1:mod(size(U,2),numel(marker_list)))];
subplot(2,2,3);
for s = 1:size(U,2)
    plot(repmat(J(s),size(U,1),1),U(:,s),m{s});
    hold on;
end
Q = polyfit(reshape(repmat(J,size(U,1),1),numel(U),1),U(:),1);
x = linspace(min(J(:))-1,max(J(:))+1,50);
y = Q(1)*x+Q(2);
plot(x,y,'k');
hold off;
xlabel('Current (\muA)');
ylabel('Voltage (mV)');
grid on;
title(sprintf('slope = %.3f, intercept = %.3f',Q(1),Q(2)));
% plot conductance
%marker list cycle index
m = [repmat(marker_list,1,floor(size(U,1)/numel(marker_list))),...
    marker_list(1:mod(size(U,1),numel(marker_list)))];
subplot(2,2,4);
for s = 1:size(U,1)
    plot(J,U(s,:),m{s});
    hold on;
end
for s = 1:size(U,1)
    plot(J,U(s,:),m{s}(1));
    hold on;
end
hold off;
xlabel('Current (\muA)');
ylabel('Voltage (mV)');
grid on;
% get a list of legend
if nargin<6 || isempty(NN_channels), NN_channels = cellfun(@num2str,num2cell(1:length(G)),'un',0);end
legend_I = cellfun(@(x,y) sprintf('g_{%s} = %.3f',char(x),y),NN_channels(:),num2cell(G),'un',0);
legend(legend_I{:},'Location','SouthEast');
title('Conductance of electrodes (mS)');
drawnow;
end

%% Statistics and Diagnostics
function SUMMARY = diagnose_S_Sigma(SUMMARY, DIAGNOSTICS, S, Sigma, numbins)
% plot diagnostics
% plot W
SUMMARY.FH = figure;
if nargin<5 || isempty(numbins), numbins = 50; end
subplot(2,4,1); hist(squeeze(S(1,1,:)),numbins); title('S_p');
subplot(2,4,2); hist(squeeze(S(1,2,:)),numbins); title('S_r');
subplot(2,4,5); hist(squeeze(S(2,1,:)),numbins); title('S_r');
subplot(2,4,6); hist(squeeze(S(2,2,:)),numbins); title('S_q');
% plot sigma
subplot(2,4,3); hist(squeeze(Sigma(1,1,:)),numbins); title('\sigma_{xx} (mS/mm)');
subplot(2,4,4); hist(squeeze(Sigma(1,2,:)),numbins); title('\sigma_{xy} (mS/mm)');
subplot(2,4,7); hist(squeeze(Sigma(2,1,:)),numbins); title('\sigma_{yx} (mS/mm)');
subplot(2,4,8); hist(squeeze(Sigma(2,2,:)),numbins); title('\sigma_{yy} (mS/mm)');
% More diagnostic summaries
% Calculate mean, median, etc. summary statistics
SUMMARY.S = calculate_summary_stats(S, 3);
SUMMARY.Sigma = calculate_summary_stats(Sigma, 3);
switch SUMMARY.method
    case 'lsq'
        SUMMARY.fvals = cellfun(@(x) x.resnorm, DIAGNOSTICS);
    case {'fmincon','fminsearch'}
        SUMMARY.fvals = cellfun(@(x) x.fval, DIAGNOSTICS);
    case 'fsolve'
        SUMMARY.fvals = cellfun(@(x) sum((x.fval).^2), DIAGNOSTICS);
end
SUMMARY.fvals_ind = find(SUMMARY.fvals == min(SUMMARY.fvals));
SUMMARY.fvals = min(SUMMARY.fvals);
SUMMARY.S.lowest_fval = squeeze(S(:,:,SUMMARY.fvals_ind));
SUMMARY.Sigma.lowest_fval = squeeze(Sigma(:,:,SUMMARY.fvals_ind));
%S = reshape(S,size(S,1)*size(S,2),size(S,3))';
%SUMMARY.S.cov = cov(S,S);
%Sigma = reshape(Sigma,size(Sigma,1)*size(Sigma,2),size(Sigma,3))';
%SUMMARY.Sigma.cov = cov(Sigma,Sigma);
suptitle(['S and \sigma distribution with ',num2str(size(S,3)),...
    ' S_0''s (',SUMMARY.method,'): fval=',num2str(SUMMARY.fvals)]);
end

% calculate simple summary stats
function STAT = calculate_summary_stats(X, dim)
switch dim
    case 0
        STAT.mean = mean(X(:));
        STAT.median = median(X(:));
        STAT.stdev = std(X(:));
        STAT.range = [min(X(:)), max(X(:))];
    otherwise
        STAT.mean = mean(X, dim);
        STAT.median = median(X, dim);
        STAT.stdev = std(X, [], dim);
        STAT.range = cat(dim, min(X, [], dim), max(X, [], dim));
end
end

function [X, IND, ISOUTLIER] = remove_outlier_Rboxplot(X, dim)
% Used R's boxplot.stats method to remove outliers from X
% Requires statistics toolbox
% [Y, IND, ISOUTLIER] = remove_outlier_Rboxplot(X, dim)
%   X: a vector or matrix
%   dim: along which dimension
% Outputs:
%   Y: data after outlier removal
%   IND: index of which the retained data used to be in X, along dimension 
%        dim
%   ISOUTLIER: matrix the size as X, labeling outlier elements as 1's
%              and others as 0's, along dimension dim
if (nargin<2 || isempty(dim)) && ndims(X)>1, dim = 1; end
if ndims(X)==1
    Notches = [-1,1]*1.58*iqr(X) + median(X);
    X = X(X>=Notches(1) & X<=Notches(2));
    ISOUTLIER = (X<Notches(1) & X>Notches(2));
    IND = find(~ISOUTLIER);
else
    Notches_size = size(X);
    Notches_size = Notches_size(setdiff(1:ndims(X),dim));
    % find positive and negative notches
    Notches_pos = median(X,dim) + 1.58.*iqr(X,dim);
    Notches_neg = median(X,dim) - 1.58.*iqr(X,dim);
    % find index where X is either greater than positive notch or less
    % than negative notches
    ISOUTLIER = bsxfun(@gt,X,Notches_pos) | bsxfun(@lt, X,Notches_neg);
    IND = find(~any(reshape(ISOUTLIER,prod(Notches_size), size(X,dim)),1));
    % remove the outliers
    %shift dimension so that the dim will now be in the first dimension
    X = shiftdim(X,dim-1);
    X_size = size(X);
    X = X(IND,:);% X becomes 2D temporarily
    %reshape back to orginal number of dimensions
    X = reshape(X, [length(IND),X_size(2:end)]);
    %shift back to original dimension
    X = shiftdim(X,ndims(X)-dim+1);
end
end

%% Utilitary subroutines
function [XY_NN,IND,Nth] = find_nearest_neighbor(MAP, XY, NN)
% Given a map of coordinates, find up to NNth nearest neighbors of 
% specified coordinate XY
% Inputs:
%   MAP and XY: coordinates of points, where each row is a point, and each
%               column is a dimension
%   NN: up to NNth neighbor to find
% 
% Outputs:
%   XY_NN: coordinates of up to NNth nearest neighbor found within MAP
%   IND: index of nearest neighbors, so that MAP(IND,:) = XY_NN
%   Nth: current point is the Nth nearest neighbor to XY on MAP.

% Eliminate XY itself from MAP
[~,IA,~] = intersect(MAP,XY,'rows','stable');
MAP = setdiff(MAP,XY,'rows','stable');
% find pairwise distance
D_mat = sqrt(bsxfun(@plus, dot(MAP,MAP,2), dot(XY,XY,2)')-2*(MAP*XY'));
[~,~,ID] = unique(D_mat);
% find up to NNth nearest neighbor
IND = find(ID<=NN);
XY_NN = MAP(IND,:);
Nth = ID(IND);
if ~isempty(IA),IND = IND + 1*(IND>=IA);end
end

function [flag,key,ind] = parse_varargin(options, varargin)
% Search for options specified in 'options'.
% input as triplet cellstrs, {'opt1','default1','key1'}.
% returns structure of flag and key with each option name, e.g. 'opt1' as
% field names
% also returns ind variable, which specifies the index mapping between
% options and varargin
flag = struct();%place holding
key = struct();%place holding
ind = [];
for n = 1:numel(varargin)
    % search if a certain option is present in the specification
    tmp = ismember(options(1:2:end),varargin{n}{1});
    if any(tmp)
        flag.(varargin{n}{1}) = options{2*find(tmp,1)};
        ind = [ind, 2*find(tmp,1) + [-1,0]];
    else
        flag.(varargin{n}{1}) = varargin{n}{2};
    end
    if numel(varargin{n})>2
        key.(varargin{n}{1}) = varargin{n}{3};
    else
        key.(varargin{n}{1}) = [];
    end
    clear tmp;
end
ind = sort(ind);
end
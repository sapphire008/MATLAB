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
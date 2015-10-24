function SUMMARY = diagnose_W_Sigma(SUMMARY, DIAGNOSTICS, W, Sigma, numbins)
% plot diagnostics
% plot W
SUMMARY.FH = figure;
if nargin<5 || isempty(numbins), numbins = 50; end
subplot(2,4,1); hist(squeeze(W(1,1,:)),numbins); title('W_a');
subplot(2,4,2); hist(squeeze(W(1,2,:)),numbins); title('W_c');
subplot(2,4,5); hist(squeeze(W(2,1,:)),numbins); title('W_b');
subplot(2,4,6); hist(squeeze(W(2,2,:)),numbins); title('W_d');
% plot sigma
subplot(2,4,3); hist(squeeze(Sigma(1,1,:)),numbins); title('\sigma_{xx} (mS/mm)');
subplot(2,4,4); hist(squeeze(Sigma(1,2,:)),numbins); title('\sigma_{xy} (mS/mm)');
subplot(2,4,7); hist(squeeze(Sigma(2,1,:)),numbins); title('\sigma_{yx} (mS/mm)');
subplot(2,4,8); hist(squeeze(Sigma(2,2,:)),numbins); title('\sigma_{yy} (mS/mm)');
suptitle(['W and \sigma distribution with ',num2str(size(W,3)),' W_0''s (',SUMMARY.method,')']);
% More diagnostic summaries
% Calculate mean, median, etc. summary statistics
SUMMARY.W = calculate_summary_stats(W, 3);
SUMMARY.Sigma = calculate_summary_stats(Sigma, 3);
switch SUMMARY.method
    case 'lsq'
        SUMMARY.fvals = cellfun(@(x) x.resnorm, DIAGNOSTICS);
    case {'fminunc','fminsearch'}
        SUMMARY.fvals = cellfun(@(x) x.fval, DIAGNOSTICS);
    case 'fsolve'
        SUMMARY.fvals = cellfun(@(x) sum((x.fval).^2), DIAGNOSTICS);
end
SUMMARY.fvals_ind = find(SUMMARY.fvals == min(SUMMARY.fvals));
SUMMARY.fvals = min(SUMMARY.fvals);
SUMMARY.W.lowest_fval = squeeze(W(:,:,SUMMARY.fvals_ind));
SUMMARY.Sigma.lowest_fval = squeeze(Sigma(:,:,SUMMARY.fvals_ind));
%W = reshape(W,size(W,1)*size(W,2),size(W,3))';
%SUMMARY.W.cov = cov(W,W);
%Sigma = reshape(Sigma,size(Sigma,1)*size(Sigma,2),size(Sigma,3))';
%SUMMARY.Sigma.cov = cov(Sigma,Sigma);
end
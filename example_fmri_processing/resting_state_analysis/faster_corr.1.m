function R=faster_corr(X,Y)
%faster way to compute Pearson's corelation
%http://stackoverflow.com/questions/9262933/what-is-a-fast-way-to-compute-column-by-column-correlation-in-matlab
X=bsxfun(@minus,X,mean(X,1));
Y=bsxfun(@minus,Y,mean(Y,1));
X=bsxfun(@times,X,1./sqrt(sum(X.^2,1))); %% L2-normalization
Y=bsxfun(@times,Y,1./sqrt(sum(Y.^2,1))); %% L2-normalization
R=sum(X.*Y,1);
end
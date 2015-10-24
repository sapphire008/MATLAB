%% Set initial W0
function W0 = set_default_test_W0(N, set_method)
if nargin<2 || isempty(set_method), set_method = 'randn'; end
% choose from v and place in k slots, with replacement
v = [-1,0,1]; k = 4;
for m = k:-1:1
    tmp = repmat(v,numel(v)^(k-m),numel(v)^(m-1));
    W0(:,m) = tmp(:);
end
% eliminate any singular initialization
W0 = reshape(W0',2,2,size(W0,1));
K = zeros(1,size(W0,3));
for k = 1:size(W0,3), K(k) = rcond(W0(:,:,k)); end
W0 = W0(:,:,find(isfinite(K) & K>1E-10)); 
W0 = reshape(W0,4,size(W0,3))';
% get random initializations
drawN = round((N-size(W0,1))/2);
while size(W0,1)<N
    % randomly draw drawN
    switch set_method
        case 'randn'
            tmpW0 = randn(2,2,drawN);
        case 'rand'
            tmpW0 = rand(2,2,drawN)-0.5;
    end
    % eliminate singular initialization
    K = zeros(1,size(tmpW0,3));
    for k = 1:size(tmpW0,3), K(k) = rcond(tmpW0(:,:,k)); end
    tmpW0 = tmpW0(:,:,find(isfinite(K) & K>1E-10));
    W0 = unique([W0; reshape(tmpW0,4,size(tmpW0,3))'], 'rows');
    if size(W0,1)>N, W0 = W0(1:N,:); end
    clear tmpW0;
end
end
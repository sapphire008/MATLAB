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
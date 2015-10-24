function flag = FB_check_vectors(base_dir,subject,diff_thresh)
% base_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/behav/';
% subject = 'MP020_050613';
% diff_thresh = 0.3;
blocks = {'block1','block2','block3'};
for b = 1:length(blocks)
    clear A B;
    A = load(fullfile(base_dir, subject,[blocks{b},'_vectors.mat']));
    B = load(fullfile(base_dir, subject,[blocks{b},'_estimated_vectors']));
    for n = 1:length(A.onsets)
        
        clear tmp;
        
        tmp = A.onsets{n}-B.onsets{n};
        if abs(tmp)>diff_thresh
            flag = 0;
            disp([subject,'|',blocks{b},'|',A.names{n}]);
        else
            flag = 1;
        end
        
        
    end
end
end

% %
% for n = 1:length(A.onsets)
%    A.onsets{n}-B.onsets{n}
% end
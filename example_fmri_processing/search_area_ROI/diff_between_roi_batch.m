addspm8

subjs = {'MP020'};

results=zeros(length(subjs),3);

for n = 1:length(subjs)
    roi_1=['/nfs/jong_exp/midbrain_pilots/ROIs/TR2/' subjs{n} '_050613_TR2_STNleft.nii'];
    roi_2=['/nfs/jong_exp/midbrain_pilots/ROIs/TR2/TG_ROI_reliability_061713/' subjs{n} '_TG_STNleft.nii'];
    
    [a, b, c] = diff_between_roi(roi_1,roi_2);
    results(n,1:3)=[a b c];
    %clear a b c
end

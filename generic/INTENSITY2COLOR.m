function ALPHA = INTENSITY2COLOR(IMG,C)
%convert a grayscale image to a colored image
C_IND = linspace(min(IMG(:)),max(IMG(:)),size(C,1));
D_mat = sqrt(bsxfun(@plus,dot(C_IND(:),C_IND(:),2),dot(IMG(:),IMG(:),2)')-2*(C_IND(:)*IMG(:)'));
[~,IND] = min(abs(D_mat),[],1);
ALPHA = reshape(C(IND),size(IMG));
clear C_IND D_MAT IND;
end
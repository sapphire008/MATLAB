function funcXYZ = adjust_XYZ(XYZ, ROI_mat, V)

XYZ(4,:) = 1;
for n = 1:length(V),
    tmp = (V{n}.mat) \ (ROI_mat * XYZ);
    funcXYZ{n} = tmp(1:3,:);
end



end


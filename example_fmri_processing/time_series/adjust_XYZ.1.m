function funcXYZ = adjust_XYZ(XYZ, ROImat, V);

XYZ(4,:) = 1;
for n = 1:length(V),
    tmp = inv(V(n).mat) * (ROImat * XYZ);
    funcXYZ{n} = tmp(1:3,:);
end



end


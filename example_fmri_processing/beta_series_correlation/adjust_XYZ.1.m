function funcXYZ = adjust_XYZ(XYZ, ROImat, V);

XYZ(4,:) = 1;
for n = 1:length(V),
    if(iscell(V)),
       tmp = inv(V{n}.mat) * (ROImat * XYZ); 
    else
        tmp = inv(V(n).mat) * (ROImat * XYZ);
    end
    funcXYZ{n} = tmp(1:3,:);
end



end


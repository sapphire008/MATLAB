function XYZ = exclude_XYZ_address(XYZ1,mat1,XYZ2,mat2);
% XYZ = exclude_XYZ_address(XYZ1,MAT1,XYZ2,MAT2);
% XYZ = all the address in XYZ2 that are not in XYZ1



% translate to image space
XYZ1(4,:) = 1;
XYZ2(4,:) = 1;

XYZ1 = round(mat1 * XYZ1);
XYZ2 = round(mat2 * XYZ2);


% find intersect of  X Y and Z
common_z = intersect(XYZ1(3,:,:),XYZ2(3,:,:));
common_y = intersect(XYZ1(2,:,:),XYZ2(2,:,:));
common_x = intersect(XYZ1(1,:,:),XYZ2(1,:,:));
% if any of the comon x y z are empty then no data is in the same location
if (isempty(common_z) | isempty(common_x) | isempty(common_y))
    
    XYZ = XYZ2;
    
else
    XYZ = [];
    for n = 1:size(XYZ2,2)
        if ~sum((XYZ1(1,:) == XYZ2(1,n)) & (XYZ1(2,:) == XYZ2(2,n)) & (XYZ1(3,:) == XYZ2(3,n)))
            XYZ(:,end+1) = XYZ2(:,n);
        end
    end  
end

XYZ = round(inv(mat2) * XYZ);
XYZ = XYZ(1:3,:);


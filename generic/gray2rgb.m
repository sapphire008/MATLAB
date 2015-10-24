function I = gray2rgb(I)
I = repmat(I, [1,1,3]);%iso-type
%rgbImage = repmat(double(grayImage)./255,[1 1 3]);uint8 gray to double RGB
%rgbImage = repmat(uint8(255.*grayImage),[1 1 3]);%double gray to uint8 RGB
end
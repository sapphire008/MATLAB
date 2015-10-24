function [COUNT,X] = imhist3(I,varargin)
% imhist for 3D image
% depends on imhist from Image Processing Toolbox
if isempty(which('imhist'))
    error('Function depends on IMHIST from Image Processing Toolbox\n');
end
% get the histogram
if nargout <1
    imhist(I(:),varargin{:});
else
    [COUNT,X] = imhist(I(:),varargin{:});
end
% plot the histogram

end
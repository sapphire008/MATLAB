function I = generateProcessedImage(I, Pallete, rotDeg, filterOpt)
% Preprocess image
% Inputs:
%   I: a single image matrix
%   Pallete: hard intensity threshold, default is [10, 650]
%   rotDeg: degree of rotation. Rotation is necessary to make sure that the
%           stripes artifacts are vertical. Default 90.
%   filterOpt: vertical stripe filtering option, in the format of cell
%       array {decNum, wname, sigma}. See XREMOVESTRIPESVERTICAL for
%       details. Input -1 to skip filtering

if nargin<2 || isempty(Pallete), Pallete = [10, 650]; end
if nargin<3 || isempty(rotDeg), rotDeg = 90; end
if nargin<4 || isempty(filterOpt), filterOpt = {8,'db42',8}; end
% scale the image by Pallete
I(I<Pallete(1)) = 0; I(I>Pallete(2)) = Pallete(2);
%I = mat2gray(I, Pallete);
% rotate the image by 90 degrees
I = imrotate(I,rotDeg);
% filter stripes
if isnumeric(filterOpt), return; end
%I = xRemoveStripesVertical(I,filterOpt{:});
end
function Vo = beta_series_contrasts(file_list,contrast,outfile)
% beta_series_contrasts(file_list,contrast,outfile)
% Inputs:
% file_list - a list of the Z-images to be included in the contrast - use char command
% contast - a vector with length equal to the number of Z-images
% outfile - string containing output file name
% 
% Ouput:
% Vo - spm_vol file array handle of the output image

% strip out the parts of the outfile name
[pathstr,name,ext] = fileparts(outfile);

% build a sring that defines the contrast operations
fstr = '';
for n = 1:length(contrast),
    if n > 1, fstr = [fstr ' + ']; end
    fstr = [fstr, '(', num2str(contrast(n)),' * i',num2str(n),')'];
end

Vi = spm_vol(char(file_list));  % make a data structure of contrast images

% build a data structure for output file - Note! all images a assume to be
% the same size
Vo = struct (...
    'fname',      [name,ext], ...
    'dim',        [Vi(1).dim], ...
    'dt',         [16, 0], ...
    'mat',        Vi(1).mat, ...
    'descript',   name);

cwd = pwd;

cd(pathstr);

% make and save the contrast
Vo   = spm_imcalc(Vi,Vo,fstr);

cd(cwd);


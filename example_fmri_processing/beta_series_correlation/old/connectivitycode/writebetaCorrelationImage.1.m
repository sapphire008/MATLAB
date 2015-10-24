function writebetaCorrelationImage( Cout, imagename, xVol)
% writeCorrelationImage( Cout, imagename,xVol)
% Cout - a vector contanining the correlations
% imagename - what the file is to be called, can include the full path
% xVol - A sub set of the SPM data structure.

nvoxels = size(xVol.XYZ,2); % length of real data in brain - should match the length of Cout
corrData = NaN * ones(xVol.DIM(1),xVol.DIM(2),xVol.DIM(3)); % array of NaN size of brain volumne

% replace NaN's with corr results
for i = 1:nvoxels,
    corrData(xVol.XYZ(1,i),xVol.XYZ(2,i),xVol.XYZ(3,i)) = Cout(i);
end


[pathstr,name,ext] = fileparts(imagename);

% make nifti data structure see spm_vol - dt is [32 bit float, little endian]
CorrIm = struct ('fname', [name,ext], ...
    'dim',        [xVol.DIM'], ...
    'dt',         [16, 0], ...
    'mat',        xVol.M, ...
    'pinfo',      [1 0 0]', ...
    'descript',   'beta-correlation');




cwd = pwd;
cd(pathstr);

CorrIm = spm_create_vol(CorrIm, 'noopen');
CorrIm = spm_write_vol( CorrIm, corrData );

cd(cwd);
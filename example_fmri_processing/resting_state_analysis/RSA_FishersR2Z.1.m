function V_out = RSA_FishersR2Z(V_in)
% Convert Pearson's R to Z score using Fisher's R to Z transformation
%
% V_out = RSA_FishersR2Z(V_in)
%
% Inputs:
%   V_in: input volume of correlation map. Either as a path to the volume, 
%         or object loaded by spm_vol
%
% Ouputs:
%   V_out: output volume of z-score map. Will also save a copy of this
%          output in the same directory as the input, with the letter 'z'
%          prepended

if ischar(V_in)
    V_in = spm_vol(V_in);
end
% convert from R to Z
Y = double(V_in.private.dat);
Y(Y>(1-1E-5)) = NaN;%remove values close to 1
Y(Y<1E-5) = NaN;%remove vlaues close to 0
Y = atanh(Y);
% write out the image
V_out = V_in;
[PATHSTR,NAME,EXT] = fileparts(V_in.fname);
V_out.fname = fullfile(PATHSTR,['z_',NAME,EXT]);
V_out = spm_create_vol(V_out);
V_out = spm_write_vol(V_out,Y);
clear PATHSTR NAME EXT Y;
end
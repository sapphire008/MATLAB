function V = spm_corr2z(P,Q,mode)
if ischar(P),P = spm_vol(P);end
if nargin<3 || isempty(mode), mode = 1;end
% create new file
V = P;
V.fname = Q;
V = spm_create_vol(V);
% write converted data to new file
switch mode
    case 1
        V = spm_write_vol(V,atanh(double(P.private.dat)));
    otherwise
        V = spm_write_vol(V,atanh(double(P.private.dat)/sqrt(mode -3)));
end
end
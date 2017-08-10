function nima = xRemoveStripesVertical(ima, decNum, wname, sigma)
% Stripe and Ring artifact remover
%
% nima = xRemoveStripesVertical(ima, decNum, wname, sigma)
% 
% Inputs:
%   ima: image matrix
%   decNum: highest decomposition level (L). Default 8.
%   wname: wavelet type. See WFILTERS.
%   sigma: damping factor of Gaussian function
%       g(x_hat, y_hat) = 1 - exp(-y_hat^2 / (2 * sigma^2))
%       Default 8.
%
% Output:
%   nima: filtered image
% 
% From 
% Beat Munch, Pavel Trtik, Federica Marone, Marco Stampanoni. Stripe and 
% ring artifact removal with combined wavelet -- Fourier filtering. Optics
% Express. 17(10): (2009)
%
% Suggestion for parameters:
% Based on the above cited paper, 
%   For waterfall artifacts (vertical stripes),
%       decNum>=8, wname='db42', sigma>=8
%   For ring artifacts
%       decNum>=5, wname='db30', sigma>=2.4
% 

% wavelet decomposition
Ch = cell(1,decNum);
Cv = cell(1,decNum);
Cd = cell(1,decNum);
for ii=1:decNum
    [ima,Ch{ii},Cv{ii},Cd{ii}]=dwt2(ima,wname);
end

% FFT transform of horizontal frequency bands
for ii=1:decNum
    % FFT
    fCv=fftshift(fft(Cv{ii}));
    [my,mx]=size(fCv);
    
    % damping of vertical stripe information
    damp=1-exp(-[-floor(my/2):-floor(my/2)+my-1].^2/(2*sigma^2));
    fCv=fCv.*repmat(damp',1,mx);
    
    % inverse FFT
    Cv{ii}=ifft(ifftshift(fCv));
end

% wavelet reconstruction
nima=ima;
for ii=decNum:-1:1
    nima=nima(1:size(Ch{ii},1),1:size(Ch{ii},2));
    nima=idwt2(nima,Ch{ii},Cv{ii},Cd{ii},wname);
end
end
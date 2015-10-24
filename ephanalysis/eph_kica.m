function W = kica(xx)
% Kurtosis Maximization ICA in two lines.
%
% W = kica(xx)
%
% W is the unmixing matrix, xx is the mixed signals, where each column is
% a dimesnion (as one microphone measurement in the classical cocktail
% party problem), and each row is an observation (over time).
%
% From Sam Roweis, NYU, shown by Yair Weiss and Eero Simoncelli.
% http://cs.nyu.edu/~roweis/kica.html
% August 4, 2014

% Whiten the signal to second order. THis makes the unmixing matrix always
% orthogonal to each other.
yy = sqrtm(inv(cov(xx')))*(xx-repmat(mean(xx,2),1,size(xx,2)));
% Map the fourth order statistics down into a funny matrix such that the
% inner product of a unit vector with this matrix gives (roughly) the 
% kurtosis in that direction. The maximal eigenvectors of this new matrix 
% are the (orthogonal) directions of maximum kurtosis which for 
% supergaussian sources are pretty good guesses at the unmixing directions.
[W,ss,vv] = svd((repmat(sum(yy.*yy,1),size(yy,1),1).*yy)*yy');
end
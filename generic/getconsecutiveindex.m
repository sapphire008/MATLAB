function f = getconsecutiveindex(t, N)
% Given sorted array of integers, 
% find the start and end of consecutive blocks
% E.g. t = [-1, 1,2,3,4,5, 7, 9,10,11,12,13, 15], 
% return [2,6; 8,12]
if nargin<2, N = 1; end
x = diff(t(:)')==1;
f = find([false,x]~=[x,false]);
f = reshape(f, 2, length(f)/2)';
f = f(find(diff(f,[],2)>=N),:); % filter for at least N consecutvie
end

function delta = eph_dirac(ts,dur,phi,h,collapse)
% Make (Summed) Dirac Delta function
%
% delta = eph_dirac(ts, dur, phi, h, collapse)
%
% Inputs:
%   ts: sampling rate in seconds. Default is 1 second.
%   dur: duration of the time series in seconds. 
%        ~Input a single value so that the time window is twice of this 
%         input, centered at 0. e.g. dur = 5 --> [-5, 5] time window
%        ~Alternatively, input as a time window in seconds, e.g.
%         dur = [-2, 5].
%        ~If no input, default [-1, 1] window.
%   phi: phase shift [seconds] of the Delta function. Default is 0 as in
%        classic Dirac delta function. Input as a vector to return one 
%        Delta function for each phi.
%   h: Height of the singularity (origin) where non-zero value occur.
%      Deafult heigth is 1.
%   collapse: [true|false] collaspe Dirac function with different phase
%      shift by adding across phi (columns). Default is true.
%
% Output:
%   delta: if not collpased, returns a matrix with row corresponding to 
%          time and columns corresponding to different phi; if collapsed, 
%          only a column vector is returned.
%
% Example usage: eph_dirac(1, [-5,5],[-2,-3,1,3],1,true). 
% Returns a column vector [0;0;1;1;0;0;1;0;1;0;0];
% 
% Depends on EPH_TIM2IND

% Parse inputs
if nargin<1 || isempty(ts), ts = 1; end
if nargin<2 || isempty(dur), dur = 1; end % Deafult [-1,1] window
if numel(dur)<2, dur = [-dur, dur]; end
if nargin<3 || isempty(phi), phi = 0; end
if nargin<4 || isempty(h), h = 1; end
if nargin<5 || isempty(collapse), collapse = true; end

% Make Dirac Delta function
phi_ind = eph_time2ind(phi,ts,dur(1)); % convert to indices
if collapse
    delta = zeros(diff(eph_time2ind(dur,ts)),1);
    delta(phi_ind) = h;
else
    % initialize matrix
    delta = zeros(diff(eph_time2ind(dur,ts)), numel(phi)); 
    for p = 1:length(phi)% for loop faster than sub2ind
        delta(phi_ind(p), p) = h;
    end
end
end
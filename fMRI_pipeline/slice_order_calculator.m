function seq = slice_order_calculator(numslices,numstacks,slicemode,positionmode,acqorder,oddfirst)
% Calcualte slice acquisition order
% seq = slice_order_calculator(numslices(t),numstacks,slicemode,positionmode,oddfirst);
% 
% Inputs:
%   numslices(t): number of slices
%   numstacks (optional): if multiplex, input a number greater than 1
%   slicemode (optional): order slices are acquired
%       'interleaved' (default)
%       'sequential'
%   positionmode(optional): the way slices are labeled
%       'f2h': foot to head (default)
%       'h2f': head to foot
%   acqorder (optional): slice acquisition order
%       'ascending': 1:1:numslices
%       'descending': numslices:-1:1
%   oddfirst (optional): whether or not odd number slice is the first. Only
%                       relevant when specifying slicemode as 'interleaved'
%       0: even first
%       1: odd first (default)
%       2: depends on number of slice, if even, start with even; if odd, 
%          start with odd

% parse optional inputs
if nargin<2 || isempty(numstacks) || numstacks<1
    numstacks = 1;
end
if nargin<3 || isempty(slicemode)
    slicemode = 'interleaved';
end
if strncmpi(slicemode,'s',1),slicemode = 'sequential';...
elseif strncmpi(slicemode,'i',1),slicemode = 'interleaved';end
if nargin<4 || isempty(positionmode)
    positionmode = 'f2h';
end
if strncmpi(positionmode,'f',1),positionmode = 'f2h';...
elseif strncmpi(positionmode,'h',1),positionmode = 'h2f';end
if nargin<5 || isempty(acqorder)
    acqorder = 'ascending';
end
if strncmpi(acqorder,'a',1),acqorder = 'ascending';...
elseif strncmpi(acqorder,'d',1),acqorder = 'descending';end
if nargin<6 || isempty(oddfirst)
    oddfirst = 1;
end

% slice acquisition order
switch slicemode
    case 'sequential'
        seq = 1:1:numslices;
    case 'interleaved'
        switch oddfirst
            case 0 %even first
                if ~strcmpi(positionmode,'h2f')
                    seq = [2:2:numslices, 1:2:numslices];
                else
                    seq = [1:2:numslices, 2:2:numslices];
                end
            case 2 %according to number of slices.
                %If even, start with even, if odd start with odd, unless in
                %'h2f' mode, keep as odd
                if mod(numslices,2) == 0 && ~strcmpi(positionmode,'h2f')
                    seq = [2:2:numslices, 1:2:numslices];
                else% even
                    seq = [1:2:numslices, 2:2:numslices];
                end
            otherwise %odd first, default
                seq = [1:2:numslices, 2:2:numslices];
        end
    otherwise
        error('unrecognized slice mode input');
end
% change slice order according to position mode (way to label slices)

switch positionmode
    case 'f2h' % foot to head, default
    case 'h2f' % head to foot, reverse the sequence order
        seq = numslices - seq + 1;
end
% change slice order according to acquisition mode (actual order of
% transversing the slices)

switch acqorder
    case 'ascending'
    case 'descending'
        seq = numslices - seq + 1;
end

% for the case with multiplex/multiplane acquisition
if numstacks > 1
    seq = bsxfun(@plus,max(seq(:))*(0:(numstacks-1))',seq);
end
end
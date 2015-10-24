function vec=eph_seriesExpansion(str)
% Produce an expanded list of series.
% Examples:
% if str = '5-10', return {'5','6','7','8','9','10'}
% if str = '5-7,12-14,17', return {'5','6','7','12','13','14','17'}
% if str = 'S1.E5-S1.E7', return {'S1.E5','S1.E6','S1.E7'}
% if str = 'S1.E5,S1.E10-S1.E11', return {'S1.E5','S1.E10',S1.E11'}
% Note that the prefix before the two numbers are identical; 
% only prefix before the series and non-numerical suffix is allowed.

%str = 'S1.E5,S1.E10-S1.E17,S1.E18-S1.E19';

if ~ischar(str)
    error('Input needs to be a string');
end

% Separate by comma
strcommalist = regexp(str,',','split');
strcommalist = cellfun(@strtrim, strcommalist,'un',0);
% Separate by dash
strdashlist = cellfun(@(x) regexp(x,'-','split'),strcommalist,'un',0);
% Expand the separated list
vec = {};
for n = 1:length(strdashlist)
    if length(strdashlist{n})<2
        vec = [vec, strdashlist{n}];
        continue; 
    end
    % if it has dash
    [num1,printformat] = matchnum(strdashlist{n}{1});
    [numlast,~] = matchnum(strdashlist{n}{end});
    num = sort([num1, numlast]);
    vec = [vec, cellfun(@(x) sprintf(printformat,x), num2cell(num(1):num(end)),'un',0)];
end
end

function [num, printformat] = matchnum(str, whichnum)
if nargin<2, whichnum = 'last'; end
printformat = regexp(str,'(\d*)','tokenExtents');
switch whichnum
    case 'first'
        ind = 1;
    case 'last'
        ind = length(printformat);
    otherwise
        if isnumeric(whichnum) && whichnum >0 && whichnum<=length(printformat) 
            ind = whichnum;
        else
            error('Invalid index of matched number');
        end
end
printformat = printformat{ind};
num = str2num(str(printformat(1):printformat(2)));
if isnan(num)
    warning('cannot detect numbers in the string'); 
    num=[];
    printformat='';
    return
end
printformat = [str(1:printformat(1)-1), '%d', str(printformat(2)+1:end)];
end
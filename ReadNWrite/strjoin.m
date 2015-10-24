function str = strjoin(C,delimiter)
if nargin<2
    delimiter = ' ';
end
str = '';
for n = 1:length(C)
    switch n
        case length(C)
            str = [str,C{n}];
        otherwise
            str = [str,C{n},delimiter];
    end
end
end
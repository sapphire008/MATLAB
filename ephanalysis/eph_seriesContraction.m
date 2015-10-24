function str = eph_seriesContraction(vect,prefix)
% Produce a contracted representation of series. For example,
% if vect = 5:10, return '5-10'
% if vect = [5:10, 12:14, 17], return '5-10,12-14,17'
% prefix: prefixing a string before each number
if nargin<2 || isempty(prefix), prefix=''; end
vd = diff(sort(vect));
ind = find(vd>1);
ind = sort([1,ind, ind+1 length(vect)]);
str = '';
for n = 1:2:length(ind)
    num = unique([vect(ind(n)), vect(ind(n+1))]);
    if numel(num)<2
        str = [str, sprintf( '%s%d', prefix, num)];
    else
        str = [str, sprintf('%s%d-%s%d', prefix,num(1),prefix, num(2))];
    end

    if n <(length(ind)-1)
        str = [str,','];
    end
    
end
end
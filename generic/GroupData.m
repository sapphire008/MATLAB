function bin_data = GroupData(data_vect,data_labels,bin_size)
%bin_data = GroupData(data_vect,data_labels,bin_size)
% data_vect:    1xN vector
% data_labels:  1xN cell array
% data_vect and data_labels must have the same length

intervals = num2cell(linspace(min(data_vect),max(data_vect),bin_size+1));
bins = cellfun(@(x,y) [x,y],intervals(1:end-1),intervals(2:end),...
    'UniformOutput',false);
bin_data = struct([]);
bin_vect = zeros(1,length(data_vect));
for n = 1:length(data_vect)
     tmp = find(cell2mat(cellfun(@(x) min(x(:))<data_vect(n) & ...
         max(x(:))>=data_vect(n),bins,'UniformOutput',false)));
     if ~isempty(tmp)
         bin_vect(n) = tmp;
     end
     clear tmp;
end

%correct minimum and maximum boundry problem
[~,min_IND]=min(data_vect);
[~,max_IND]=max(data_vect);
bin_vect(min_IND) = 1;%minimum belongs to first bin
bin_vect(max_IND) = bin_size;%maxmum belongs to last bin

%sorting everything into bins
for m = 1:length(bins)
    bin_data(m).value = data_vect(bin_vect==m);
    bin_data(m).label = data_labels(bin_vect==m);
end
end
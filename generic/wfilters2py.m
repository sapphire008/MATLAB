% print wfilters values in python syntax
filter_list = [];
A = {};
A{1} = regexp(sprintf('db%d;', 1:45),';','split');
A{2} = regexp(sprintf('coif%d;', 1:5),';','split');
A{3} = regexp(sprintf('sym%d;', 2:45),';','split');
A{4} = {'dmey',''};
A{5} = regexp(sprintf('bior%.1f;', [1.1, 1.3, 1.5, 2.2, 2.4, 2.6, 2.8, 3.1, 3.3, 3.5, 3.7, 3.9, 4.4, 5.5, 6.8]),';','split');
A{6} = regexp(sprintf('rbio%.1f;', [1.1, 1.3, 1.5, 2.2, 2.4, 2.6, 2.8, 3.1, 3.3, 3.5, 3.7, 3.9, 4.4, 5.5, 6.8]),';','split');


for n = 1:length(A)
    filter_list = [filter_list, A{n}(1:end-1)];
end

for n = 88:94%95:length(filter_list)
    [LO_D,HI_D,LO_R,HI_R] = wfilters(filter_list{n});
    fprintf('''%s'':(%s, %s, %s, %s),\n', filter_list{n}, regexprep(mat2str(LO_D),'(\s)+',','), ...
        regexprep(mat2str(HI_D),'(\s)+',','), regexprep(mat2str(LO_R),'(\s)+',','), regexprep(mat2str(HI_R),'(\s)+',','));
end
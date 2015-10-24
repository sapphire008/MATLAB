%IEX_stats
%load data from excel spread sheet
[NUMERIC,TXT,RAW]=xlsread('stat_analysis');


%do some preprocessing
%replace all the 'NA' with double NaN
NA_ind=find(strcmpi('NA',RAW));
RAW(NA_ind)=cellfun(@(x) {NaN}, RAW(NA_ind));

%replace all the illegal characters within the string
illegal_char={' ','/','.'};
text_ind=find(cellfun(@ischar,RAW));
tmp=RAW;
RAW=tmp;
for c=1:length(illegal_char)
    %trim if the first or last character is illegal
    RAW(text_ind)=cellfun(@(x) [strrep(x(1),illegal_char{c},x(2:end)),RAW(text_ind),'UniformOutput',false);
    RAW(text_ind)=cellfun(@(x) strrep(x(end),illegal_char{c},''),RAW(text_ind),'UniformOutput',false);
    RAW(text_ind)=cellfun(@(x) strrep(x,illegal_char{c},'_'),RAW(text_ind),'UniformOutput',false);
end

RAW(text_ind)=cellfun(@(x) strrep(x,illegal_char{c},'_'),RAW(text_ind),'UniformOutput',false);

[row,col]=size(RAW);
STATS.Size_X=cell2mat(RAW(2:row-1,27));
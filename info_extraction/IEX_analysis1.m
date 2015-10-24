data_flag=0;%0=good only, 1=all
[loadfile.NUMERIC,loadfile.TXT,loadfile.RAW]=...
    xlsread('movement_displacement2.xls');%read xls file
    loadfile.RAW=loadfile.RAW(2:end,:);%cut off header
if ~data_flag
    good_ind=find(~cell2mat(loadfile.RAW(:,5)));
    loadfile.RAW=loadfile.RAW(good_ind,:);
end

[params.num_run,params.num_var]=size(loadfile.RAW);%get num subj and num variables

index_mfg=strcmp('v1',loadfile.RAW(:,4));%get index of v1 subjects
subj_list.PVC=loadfile.RAW(index_mfg,:);%v1 subject trials
subj_list.PVC_sub=unique(subj_list.PVC(:,1));%v1 subjects list
subj_list.MFG=loadfile.RAW(~index_mfg,:);%mfg subject trials
subj_list.MFG_sub=unique(subj_list.MFG(:,1));%v1 subjects list


data_file_v1=fopen('output_data_v1.txt','wt');%open .csv file
for i = 1:length(subj_list.PVC_sub)
    IND=find(strcmp(subj_list.PVC_sub{i,1},subj_list.PVC(:,1)));
    for j = 2:28
        subj_list.PVC_sub{i,j}=mean(cell2mat(subj_list.PVC(IND,j+4)),1);
    end
    
    fprintf(data_file_v1,'%s \t',subj_list.PVC_sub{i,:});
    fprintf(data_file_v1,'\r\n');
end
fclose(data_file_v1);

clear i j IND;

data_file_mfg=fopen('output_data_mfg.txt','wt');%open .csv file
for i = 1:length(subj_list.MFG_sub)
    IND=find(strcmp(subj_list.MFG_sub{i,1},subj_list.MFG(:,1)));
    for j = 2:28
        subj_list.MFG_sub{i,j}=mean(cell2mat(subj_list.MFG(IND,j+4)),1);
    end
    
    fprintf(data_file_mfg,'%s \t',subj_list.MFG_sub{i,:});
    fprintf(data_file_mfg,'\r\n');
end


fclose(data_file_mfg);%close csv file
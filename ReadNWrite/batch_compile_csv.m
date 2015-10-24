%function compile_csv(data_dir,save_dir,file_suffix,file_ext,prefix,mode,varargin)
% batch compile csv
data_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/haldol/fracback_betas/extracted_betas/';
save_dir = '/hsgs/projects/jhyoon1/midbrain_pilots/haldol/';

file_suffix = {'_SNleft','_STNleft'};
file_ext = '.csv';
mode = 'concat';%['pivot' | 'concat']
prefix = 'compiled';
sortby = {'Null','ZeroBack','OneBack','TwoBack'};
tokenname = 'Subjects';

%%
for n = 1:length(file_suffix)
    files = dir(fullfile(data_dir,['*',file_suffix{n},file_ext]));
    if isempty(files)
        fprintf('File suffix does not exist: %s\n',file_suffix{n});
        continue;
    end
    % get the token of wild card
    tokens = regexp({files.name},['(\w*)',file_suffix{n},file_ext],'tokens');
    tokens = cellfun(@(x) x{1}{1},tokens,'un',0);
    % open a file to write
    if strcmpi(file_suffix{n}(1),'_')
        fname = fullfile(save_dir,[prefix,file_suffix{n},'.csv']);
    else
        fname = fullfile(save_dir,[prefix,'_',file_suffix{n},'.csv']);
    end
    
    
    switch mode
        case 'concat'
            FID = fopen(fname,'a+');
            fclose(FID);
            for f = 1:length(files)
                clear F;
                % put tokens in the worksheet
                F = ReadTable(fullfile(data_dir,files(f).name));
                F = [cellstr(repmat(tokens{f},size(F,1),1)),F]; %#ok<AGROW>
                cell2csv(fname,F,',','a+');
            end
        case 'pivot'
            P = {};
            for f = 1:length(files)
                clear F;
                % put tokens in the worksheet
                F = ReadTable(fullfile(data_dir,files(f).name));
                F = [cellstr(repmat(tokens{f},size(F,1),1)),F]; %#ok<AGROW>
                P = [P;F]; %#ok<AGROW>
            end
            % convert to pivot table
            P = pivottable(P,1,3,4, @mean);
            % replace any empty cell with NaN
            empty_ind = cellfun(@isempty,P);
            P(empty_ind) = {NaN};
            P{1,1} = tokenname;
            %sort column
            if ~isempty(sortby)
                [~,LOCB] = ismember(P(1,2:end),sortby);
                LOCA = find(LOCB);
                LOCB(LOCB==0) = [];
                tmp_P = P;
                P = {};
                P(:,1) = tmp_P(:,1);
                P(:,LOCB+1) = tmp_P(:,LOCA+1);
            end
            cell2csv(fname,P,',','w+');
    end
end



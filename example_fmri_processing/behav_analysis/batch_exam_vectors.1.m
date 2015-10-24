% batch exam vectors
base_dir = '/nfs/jong_exp/midbrain_pilots/frac_back/behav/';
subjects = {'JY_052413_haldol','MM_051013_haldol','MP020_050613',...
    'MP021_051713','MP022_051713','MP023_052013','MP024_052913',...
    'MP025_061013','MP026_062613','MP027_062713','MP028_062813',...
    'MP029_070213','MP030_070313','MP032_071013','MP033_071213',...
    'MP034_072213','MP035_072613','MP036_072913','MP037_080613',...
    'MP120_060513','MP121_060713','MP122_061213','MP123_061713',...
    'MP124_062113','MP125_072413'};
ext = 'block*_vectors.mat';
wild_card_format = '(\d?)';
ext2 = strrep(ext,'*',wild_card_format);
Correct.names{1} = {'InstructionBlock','ZeroBack','InstructionBlock',...
    'OneBack','InstructionBlock','TwoBack','NULL','InstructionBlock',...
    'OneBack','InstructionBlock','TwoBack','InstructionBlock','ZeroBack',...
    'NULL','InstructionBlock','TwoBack','InstructionBlock','ZeroBack',...
    'InstructionBlock','OneBack','NULL'};
Correct.names{2} = {'InstructionBlock','TwoBack','InstructionBlock',...
    'OneBack','InstructionBlock','ZeroBack','NULL','InstructionBlock',...
    'OneBack','InstructionBlock','ZeroBack','InstructionBlock','TwoBack',...
    'NULL','InstructionBlock','ZeroBack','InstructionBlock','TwoBack',...
    'InstructionBlock','OneBack','NULL'};
Correct.names{3} = {'InstructionBlock','ZeroBack','InstructionBlock',...
    'OneBack','InstructionBlock','TwoBack','NULL','InstructionBlock',...
    'OneBack','InstructionBlock','TwoBack','InstructionBlock','ZeroBack',...
    'NULL','InstructionBlock','TwoBack','InstructionBlock','ZeroBack',...
    'InstructionBlock','OneBack','NULL'};
Correct.onsets = [0,3,33,36,66,69,99,114,117,147,150,180,183,213,228,231,261,264,294,297,327];
for s = 1:length(subjects)
    disp(subjects{s});
    clear files;
    files = dir(fullfile(base_dir,subjects{s},ext));
    files = {files.name};
    files = files(~cellfun(@isempty,cellfun(@(x) regexp(x,ext2),files,'un',0)));
    filespath = cellfun(@(x) fullfile(base_dir,subjects{s},x),files,'un',0);
    
    % inspect each vector file
    for b = 1:length(files)
        fprintf('%s: ',files{b});
        EVENT = load(filespath{b});
        EVENT.names = cellfun(@(x,y) repmat(x,length(y),1),EVENT.names,EVENT.onsets,'un',0)';
        EVENT.names = cellstr(char(EVENT.names));%names
        EVENT.onsets = cell2mat(cellfun(@(x) x(:)',EVENT.onsets,'un',0));
        % sorting by onsets
        [EVENT.onsets,I] = sort(EVENT.onsets(:),1,'ascend');
        EVENT.names = EVENT.names(I);
        EVENT.names = EVENT.names(:);
        
        % compare current name orders
        if length(Correct.names{b}) ~= length(EVENT.names)
            fprintf('event name not the same length');
        elseif any(~strcmpi(Correct.names{b}(:),EVENT.names(:)))
            fprintf('event name not matched, ');
        else
            fprintf('event okay, ');
        end
        
        % compare onset time
        if length(Correct.onsets) ~= length(EVENT.onsets)
            fprintf('onset length are not the same\n');
        elseif any(abs(Correct.onsets(:)-EVENT.onsets(:))>1)
            fprintf('onset time not matched\n');
        else
            fprintf('onset okay\n');
        end
%         
%         for m = 1:length(EVENT.names)
%             fprintf('%s :\t %.1f\n',EVENT.names{m},EVENT.onsets(m));
%         end
%         pause;

    end

end

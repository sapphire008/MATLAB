function list_contrasts(SPM)
S = warning('QUERY', 'BACKTRACE');
warning off;
if nargin<1 && ~exist('SPM','var')
    W = evalin('caller','whos'); %'base' or 'caller'
    if ~ismember('SPM',{W(:).name})
        try
            load('SPM.mat');
        catch ERR
            error('SPM does not exist!');
        end
    else
        SPM = evalin('caller','SPM');
    end
end
if ischar(SPM),load(SPM);end
if ~isfield(SPM,'xCon'),error('contrasts do not exist!\n');end
if isempty(SPM.xCon)
    disp('There are no contrasts in current design!');
    return;
end
for n = 1:length(SPM.xCon)
   fprintf('%d : %s\n',n,SPM.xCon(n).name); 
end
warning(S);
end
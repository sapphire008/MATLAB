function list_betas(SPM)
S = warning('QUERY', 'BACKTRACE');
warning off;
if nargin<1
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
if ~isfield(SPM,'Vbeta')
    error('betas do not exist!\n');
end
if isempty(SPM.Vbeta)
    disp('There are no betas in current design!');
    return;
end
for n = 1:length(SPM.Vbeta)
   fprintf('%d : %s\n',n,SPM.Vbeta(n).descrip); 
end
warning(S);
end
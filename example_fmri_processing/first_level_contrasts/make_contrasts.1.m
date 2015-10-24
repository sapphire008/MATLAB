function contrasts = make_contrasts(SPM_loc,positive_cons,negative_cons,name,sumtozero)
% Pass in SPM data structure
% if you want to make sure the contrasts sum to zero - set sumtozero to 1

% Following lines should be changed to match your desired contrasts
% Note number of positive strings must equal number of negative strings
% if you want to do vs baseline set the negative string to 'constant'

% If you do not want to use custom names set custom_names to zero

% modifed to remove contrasts that are all zero DMT 8/15/12
if isempty(name)
    custom_name = 0;
else
    custom_name = 1;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch exist('SPM_loc')
    
    case 0 % no SPM_loc passed in
        disp(' Need to provide SPM.mat file');
        contrasts = 'Empty Need to provide SPM.mat file to make_contrasts';
        return
    case 1 % SPM structure or location
        if ischar(SPM_loc),
            disp('Load SPM.mat file');
            load(SPM_loc);
            clear('SPM_loc');
        elseif iscell(SPM_loc),
            SPM = SPM_loc;
            clear('SPM_loc');
        end
    otherwise
        disp(' Need to provide SPM.mat file');
        contrasts = 'Empty Need to provide SPM.mat file to make_contrasts';
        return
end

if ~exist('sumtozero'), sumtozero = 0; end

good_con = [];  %used at end of script

%%%%%%%%%%%%%%%%%%%% change nothing below here %%%%%%%%%%%%%%%%%%%%%%%%%%%


for n = 1:length(positive_cons)
    
    contrasts(n).con = zeros(1,length(SPM.Vbeta));
    %%%%%%%% make contrast name %%%%%%%%%%%%
    if custom_name %name is defined by user
        contrasts(n).name = name{n}; % allow for custom names
    else
        % name is constructed from Beta names
        contrasts(n).name = '';
        for k = 1:length(positive_cons{n})
            contrasts(n).name = [contrasts(n).name positive_cons{n}{k}];
            if k < length(positive_cons{n})
                contrasts(n).name = [contrasts(n).name '+'];
            end
        end
        
        contrasts(n).name = [contrasts(n).name '-'];
        
        for k = 1:length(negative_cons{n})
            contrasts(n).name = [contrasts(n).name negative_cons{n}{k}];
            if k < length(negative_cons{n})
                contrasts(n).name = [contrasts(n).name '-'];
            end
        end
    end
    
    %%%%%%%%% Match Beta Names to generate contrasts %%%%%%%%%
    null_counter = 0;
    for k = 1:length(positive_cons{n})
        if strcmpi(negative_cons{n},'null')
             null_counter = null_counter +1;
        end
        idx = strfind({SPM.Vbeta.descrip},positive_cons{n}{k});
        idx = find(~cellfun('isempty',idx));
        contrasts(n).con(idx) = 1;
    end
    
    for k = 1:length(negative_cons{n})
        if strcmpi(negative_cons{n},'null')
            null_counter = null_counter +1;
        end
        idx = strfind({SPM.Vbeta.descrip},negative_cons{n}{k});
        idx = find(~cellfun('isempty',idx));
        contrasts(n).con(idx) = -1;
    end
    
    %%%%%%%%% Adjusts contrast if sumtozeros is true and negative_con is defined %%%%%%%%%

    if (sumtozero && ~isempty(negative_cons{n}) && ~isempty(positive_cons{n})) && null_counter==0
        pos = find(contrasts(n).con > 0);
        neg = find(contrasts(n).con < 0);
        if length(neg) > length(pos),
            contrasts(n).con(neg) = contrasts(n).con(neg) * (length(pos)/length(neg));
        else
            contrasts(n).con(pos) = contrasts(n).con(pos) * (length(neg)/length(pos));
        end
    end
    
end

%% this block of will remove any contrasts with only zero elements
k = 1;
for n = 1:length(contrasts),
    if(find(contrasts(n).con)),
        foo(k)=contrasts(n);
        k = k+ 1;
    end
end
if exist('foo')
    contrasts = foo;
end

    










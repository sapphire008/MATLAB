function contrasts = make_contrasts_riss_conn(file_list,positive_cons,negative_cons,name,sumtozero)
% Inputs:
%   file_list: list of files to do contrast with. Name of the file must
%              be labeled with the conditions
%   positive_cons/negative_cons: condition names. Note number of positive 
%              strings must equal number of negative strings
%   name: custom condition name
%   sumtozero: [true|false] adjust contrast vector so that the sum of the
%              vector is zero, except with there is null condition involved
%
% Ouput:
%   contrasts: a structure that contains all the contrast information

% modifed to remove contrasts that are all zero DMT 8/15/12
if isempty(name)
    custom_name = 0;
else
    custom_name = 1;
end

if ~exist('sumtozero'), sumtozero = true; end

good_con = [];  %used at end of script

%%%%%%%%%%%%%%%%%%%% change nothing below here %%%%%%%%%%%%%%%%%%%%%%%%%%%


for n = 1:length(positive_cons)
    
    contrasts(n).con = zeros(1,length(file_list));
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
        idx = strfind(file_list,positive_cons{n}{k});
        idx = find(~cellfun('isempty',idx));
        contrasts(n).con(idx) = 1;
    end
    
    for k = 1:length(negative_cons{n})
        if strcmpi(negative_cons{n},'null')
            null_counter = null_counter +1;
        end
        idx = strfind(file_list,negative_cons{n}{k});
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

    










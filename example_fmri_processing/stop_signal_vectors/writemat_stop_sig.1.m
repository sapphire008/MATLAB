function writemat(str,name,outname,Vectors)
% writemat(str,name,varargin)
% str = string to subject directories
% name = string "subject name"
% Vectors = Cell array - datain Name Data pairs
% example {{{'CorrectCorrect'},CC}, {{'CorrectIncorrect'},CI}} where CC and CI are onset vectors
% and 'CorrectCorrect', 'CorrectIncorrect' are how we name them in the
% estimates
wd = cd;

 try 
     cd([str,name]),
 catch
  disp(['Subject ',name,' Dir does not exist!  Makeing path']);
  mkdir([str,name]), 
  cd([str,name]);
 end


for n = 1:length(Vectors)
    % single block code
    %fullnames{n} = Vectors{n}{1}{1};
    %fullonsets{1}{n} = Vectors{n}{2}; % onsets{block}{Condition}
    %fulldurations{n} = [0];
    
    
    fullnames{n} = Vectors{n}{1}{1};
    for k = 1:length(Vectors{n}{2})
        fullonsets{k}{n} = Vectors{n}{2}{k}; % onsets{block}{Condition}
    end
%     if n==1
%         fulldurations{1} = [1];
%     elseif n==2
%         fulldurations{2} = [2];
%     elseif n==5
%         fulldurations{5} = [1];
%     elseif n==6
%         fulldurations{6} = [1];  
%     else
%     fulldurations{n} = [0];
%    end
fulldurations{n} = 0;
end

blocks = length(fullonsets);

for n = 1:blocks,
    [names, durations, onsets] = check_empty(fullnames, fulldurations, fullonsets{n});
    file = [outname,'_',num2str(n)];
    file = ['save ',file,' names durations onsets'];
    eval(file);
    clear names durations onsets;
end


cd(wd);


function [knames, kdurations, konsets] = check_empty(names, durations, onsets)

k = 1;
for n = 1:length(onsets),
    if(~isempty(onsets{n})),
        konsets{k} = onsets{n};
        knames{k} = names{n};
        kdurations{k} = durations{n};
        k = k + 1;
    end
end


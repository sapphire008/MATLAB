function outPath = workPathToAnalysisPath(rawWorkPath)
    % revised 28 Jan 2015 BWS
    % takes the path to the core project folder and generates daily folder
    % example input: D:/Dropbox/Work/Projects/Poly3
    %   outPath = D:/Dropbox/Work/Projects/Poly3/Analysis/2015 01 23/
    % This function will create subfolders (eg 2015 01 23) if needed
    
    workPath = strtrim(rawWorkPath); % string trim
    workPath = strrep(workPath, '\', '/'); % convert to all / slashes
    if ~strcmp(workPath(end), '/'), workPath = [workPath '/']; end
    nowDateStr = datestr(now,'yyyy mm dd'); 
    outPath = [workPath 'Analysis/' nowDateStr];
    if ~isdir(outPath)
      status = mkdir(outPath);
       if status == 1 
           disp(['Created new folder: ' outPath]);
       else
           disp(['Problem creating new folder: ' outPath]);
       end
    end
end
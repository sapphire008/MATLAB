function savedTableFileName = saveTableAsCSV(mTable, tagStr, projectPath)
    % revised 28 Jan 2015 BWS
    
    outPath = workPathToAnalysisPath(projectPath);
    nowDateStr = datestr(now,'dd mmm yy'); 
    savedTableFileName = [outPath '/' tagStr '.' nowDateStr '.csv'];
    writetable(mTable, savedTableFileName);
end
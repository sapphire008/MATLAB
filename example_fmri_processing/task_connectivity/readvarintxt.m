function DICT = readvarintxt(file_dir)
DICT = [{},{}];
c = 1;
FID = fopen(file_dir);
if FID<0
    error('cannot open file!');
end
while true
    current_line = fgets(FID);
    if isnumeric(current_line) && current_line<0
        fclose(FID);
        break;
    end
    DICT(c,1:2) = regexp(current_line,'=','split');
    DICT(c,1:2) = cellfun(@strtrim,DICT(c,1:2),'un',0);
    DICT(c,1:2) = cellfun(@strtok,DICT(c,1:2),{'_','_'},'un',0);
    c = c + 1;
end
end
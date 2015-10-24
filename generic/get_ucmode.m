function get_ucmode(fname)
if ~exist('fname', 'var')
    fname = 'image_1.dcm';
end
if ~exist(fname, 'file')
     error('file %s does not exist', fname);
end
info = dicominfo(fname);
str = info.Private_0029_1020;
xstr = char(str');
n = findstr(xstr, 'sSliceArray.ucMode');
[t, r] = strtok(xstr(n:n+100), '=');
ucmode = strtok(strtok(r, '='));
switch(ucmode)
    case '0x1'
        disp([fname ': Ascending']);
    case '0x2'
        disp([fname ': Descending']);
    case '0x4'
        disp([fname ': Interleaved']);
    otherwise
        disp([fname ': Order undetermined']);
end

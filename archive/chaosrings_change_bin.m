save_file_path = 'C:\Users\Edward\Desktop\Documents\data002.bin';
% open the file to read
fid = fopen(file2,'r');
fseek(fid,0,-1);

A = [];

while ~feof(fid);
    A = [A,fread(fid, 1, 'uchar')];
end

fclose('all');
A = A';


file1 = 'C:\Users\Edward\Desktop\Documents\data001.bin';
file2 = 'C:\Users\Edward\Desktop\Documents\data003.bin';

visdiff(file1, file2)

8360
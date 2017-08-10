function buildSource(browseOnly, abfSupport)

if nargin < 1
    browseOnly = 0;
end
if nargin < 2
    abfSupport = 0;
end

% this just compiles the source using mcc
installDir = which('buildSource');
installDir = installDir(1:find(installDir == filesep, 1, 'last'));      

fid = fopen([installDir 'experiment.prj'], 'w');

% compile to run hardware if 32 bit, analysis if 64 bit
if ~browseOnly
    mainName = ['         <file>' fullfile(installDir, 'acquire', 'experiment', 'experiment.m') '</file>'];
else
    mainName = ['         <file>' fullfile(installDir, 'FileBrowser', 'fileBrowser.m') '</file>'];
end

% first generate a project file
staticData = {'<?xml version="1.0" encoding="utf-8"?>',...
        '<project><!--experiment.prj-->',...
        '   <MCCProperties>',...
        '      <output>experiment</output>',...
        '      <wrapper>',...
        '         <type>main</type>',...
        '         <component_name>experiment</component_name>',...
        '         <default_class>Main function</default_class>',...
        '      </wrapper>',...
        '      <intermediate_dir>$(PROJECTDIR)/experiment</intermediate_dir>',...
        '      <output_dir>$(PROJECTDIR)/experiment/distrib</output_dir>',...
        '      <link>exe</link>',...
        '      <MCR_runtime_options/>',...
        '      <generate_code_only>false</generate_code_only>',...
        '      <verbose>true</verbose>',...
        '      <options_file/>',...
        '      <debug>false</debug>',...
        '      <toolboxes_on_path shortcut="all"/>',...
        '      <warning shortcut="default">',...
        '         <warn name="specified_file_mismatch">enable</warn>',...
        '         <warn name="repeated_file">enable</warn>',...
        '         <warn name="switch_ignored">enable</warn>',...
        '         <warn name="missing_lib_sentinel">enable</warn>',...
        '         <warn name="demo_license">enable</warn>',...
        '      </warning>',...
        '   </MCCProperties>',...
        '   <file_info>',...
        '      <category name="Main function"><!--Do not modify the value of the name attribute, unless it is a class name.-->',...
        mainName,...
        '      </category>',...
        '      <category name="Other files"><!--Do not modify the value of the name attribute, unless it is a class name.-->'};
for i = staticData
    fprintf(fid, '%s\n', i{1});
end

% add in additional files
    dirStack{1} = installDir;
    dirPointer = 1;
    while dirPointer <= numel(dirStack)    
        %generate a list of all directories in the current directory
        currentDir = dirStack{dirPointer};
        tempDir = dir(currentDir);
        whichFiles = find(cat(2,tempDir.isdir));
        for q = 1:size(whichFiles, 2)
            tempFile = tempDir(whichFiles(q)).name;
            if tempFile(1,1) ~= '.' && (abfSupport || isempty(strfind(tempFile, '(ABF)')))
                dirStack{end + 1} = [currentDir filesep tempFile];
            end
        end
        
        %check all files in current directory
        for fileName = {tempDir(~cat(2, tempDir.isdir)).name};
            fprintf(fid, '         <file>%s</file>\n', [currentDir filesep fileName{1}]);
        end
        dirPointer = dirPointer + 1;
    end

staticData = {'      </category>',...
    '      <category name="C/C++ files"><!--Do not modify the value of the name attribute, unless it is a class name.--></category>',...
    '   </file_info>',...
    '   <packaging>',...
    '      <name>mPhys_full</name>',...
    '      <mcr include="true">',...
    '         <location>default</location>',...
    '      </mcr>',...
    '      <additional_files/>',...
    '   </packaging>',...
    '   <MATLABPath>',...
    '      <Directory>$(MATLABROOT)/toolbox/compiler/deploy</Directory>}'};
for i = staticData
    fprintf(fid, '%s\n', i{1});
end

% add in matlab path
staticData = path;
newPath = [0 find(staticData == pathsep) length(staticData) + 1];
for i = 1:numel(newPath) - 1
    fprintf(fid, '      <Directory>%s</Directory>\n', staticData(newPath(i) + 1:newPath(i + 1) - 1));
end

fprintf(fid, '%s\n', '    </MATLABPath>');
fprintf(fid, '%s\n', '</project>');

fclose(fid);

deploytool('experiment.prj')

% % compile and package
% mkdir(installDir, 'experiment');
% mcc('-F', [installDir 'experiment.prj']);
% 
% % write a readme file
% fid = fopen([installDir '\experiment\readme.txt'], 'w');
%     fprintf(fid, '%s\n', 'This must be deployed with both the standalone library and the .ctf file in order to work.');
%     fprintf(fid, '%s\n', 'If you will deploy to users who have not had deployed matlab applications in the past, you must also provide a copy of matlabroot/toolbox/compiler/deploy/arch/MCRInstaller (where arch is the target computer architecture) that needs to be self-extracted by the user.');
% fclose(fid);
% 
% % create an installer file
% fid = fopen(fullfile(installDir, 'experiment', '_install.bat'), 'w');
%     fprintf(fid, '%s\n', 'echo off');
%     fprintf(fid, '%s\n', 'echo Deploying project experiment.');
%     fprintf(fid, '%s\n', 'IF EXIST MCRInstaller.exe (');
%     fprintf(fid, '%s\n', 'echo Running MCRInstaller');
%     fprintf(fid, '%s\n', 'MCRInstaller.exe');
%     fprintf(fid, '%s\n', ')');
%     fprintf(fid, '%s\n', 'echo Installation complete.');
%     fprintf(fid, '%s\n', 'echo Please refer to the documentation for any additional setup steps.');
% fclose(fid);
% 
% % package
% platform = computer('arch');
% deployDir = fullfile(matlabroot, 'toolbox', 'compiler', 'deploy');
% platformDir = fullfile(deployDir, platform);
% if ispc
%     installer = fullfile(platformDir, 'MCRInstaller.exe');
% elseif ismac
%     installer = fullfile(platformDir, 'MATLAB_Component_Runtime.dmg');
% else
%     installer = fullfile(platformDir, 'MCRInstaller.bin');
% end
% package_prj(fullfile(installDir, 'experiment', 'mPhys_full'), {'_install.bat', installer, 'experiment.exe'}, fullfile(installDir, 'experiment'));
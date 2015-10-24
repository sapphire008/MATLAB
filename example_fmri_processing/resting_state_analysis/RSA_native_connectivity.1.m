function [BATCH] = RSA_native_connectivity(P,S,M,ROI,R,save_conn,varargin)
% Perform native space single subject functional connectivity analysis. 
% Adapted from the conn toolbox from http://web.mit.edu/swg/software.htm 
% by Susan Whitfield-Gabriedli.
% 
% RSA_native_connectivity(P,S,M,ROI,R,...)
% 
% Inputs:
%   P: Source functional images for current subject. All the volumes of one
%      session should be arranged in character arrays (use char to convert
%      cellstr to character array). For multiple sessions of the same
%      subject, use multiple cells.
%
%   S: Source structural image for current subject. Specify as a character
%      array for current subject
%
%   M: Source mask images. A structural contains the paths to 3 different 
%      masks. M contains the following fields
%      M.Bin.files: binary mask directory
%      M.Bin.res: mask resolution. 1 for same as template, 2 for same as
%                 structural, and 3 for same as functional
%      M.Grey.files: grey matter mask
%      M.Grey.dimensions: (optional) Number of PCA components to extract.
%                          Default 1, or the mean BOLD signal
%      M.White.files: white matter mask
%      M.White.dimensions: (optional) Number of PCA componenets to extract.
%                           Default 16
%      M.CSF.files: cerebral-spinal fluid mask
%      M.CSF.dimensions: (optional) Number of PCA componenets to extract.
%                        Default is 16
%      M.[Grey/White/CSF].cutoff: (optional) Relevant in confound analysis.
%                        input as a numeric to parse how many componenets 
%                        to use (first 3 usually account for most of the 
%                        variance). Default is 1 for Grey, 3 for White and 
%                        CSF. Alternatively, use a string, for instance,
%                        '99%' to indicate that select a certain number of
%                        components to account for certain percentage of
%                        variance.
%   ROI: Structure that specifies ROI seeds, with the following fields
%      ROI.names: cell array of ROIs' names.
%      ROI.files: cellstr of ROI directories
%      ROI.dimensions: (optional) cell array of numerics. 
%              This specifies how many components to extract from each ROI.
%              Default is 1, or mean of each ROI.
%      ROI.deriv: (optional) cell array of numerics. This specifies how
%              many derivatives to use.
%      
%   R: structure that specifies the covariates, with the follwoing fields
%       R.names: cellstr of covariate names. Tripple 
%       R.files: Paths .mat or .txt files containing each covariates.
%                Triple cell array indexed by {ncov}{nsubj}{nsession}
%       R.dimensions and R.deriv are similar to that of ROI
%
%   save_conn: full path to where to save the project, including a name. 
%              The project will then be saved as  /mypath/conn_*.mat
%
%   Options:
%       'TR': time repetition (seconds). Default 3 seconds
%       'overwrite': ['Yes'|'No'] overwriting existing extracted data.
%                     Default 'False'.
%       'filter': band pass filtering. Specify as [high_pass, low_pass]. To
%                turn off high pass filter, set as 0; To turn off low pass
%                filter, set as Inf. Default is [0, Inf]
%       'detrend': detrending each session. Default true.
%       'despike': smooth out BOLD timeseries with hyperbolic tangent
%                  squahsing function. Default false.
%       'conn_type': type of connectivity analysis to do. Only for ROI to
%                ROI or seed-to-voxel analysis. For voxel-to-voxel
%                analysis, input as a structure (See BATCH.Analysis.measure
%                under voxel-to-voxel analysis).
%           1 -- Pearson correlation of each predictor with the image time
%                series. Assuming that all predictors are independent from
%                each other (Default)
%           2 -- Semipartial correlation. This does not assume independence
%                between predictors
%           3 -- Bivariate Regression: build a linear regression model for
%                each predictor. Assuming independece between the
%                predictors.
%           4 -- Multivariate Regression: build a multivaraite linear
%                regression using all the predictors in the same model.
%       'ana_type': type of analysis to do
%           1 -- ROI to ROI analysis
%           2 -- ROI to voxel analysis (Default)
%           3 -- voxel to voxel analysis (Not fully implemented)
%       'acq': acquisition type.
%           0 -- sparse, with breaks within session. This will skip the
%                convolution with HRF
%           1 -- continuous
%       'weight': weighting of each volume within a block . Default is HRF.
%                 See conn documentation on BATCH.Analysis.weight
%       'num': analysis number (used as a label for different types of 
%              analyses. Default is 1. Must be set to 0 when ana_type is 3
%
%
% Outputs variables:
%       BATCH: model specification structure. Just like matlabbatch in SPM.
% 
% Output files:
%   Change default output at outtypes variable
%       1). 4D image with confound-corrected BOLD timeseries
%       2). If ana_type is 2 and conn_type is 1 or 2, output correlation
%           map.
%       3). If ana_type is 2 and conn_type is 1 or 2, output FDR corrected
%           p value map


% **************************  Analysis Details  ***************************
% 1). Basis condition: onset at 0, duration is the duration of one session
%     Only 1 condition within each session. This condition set-up is
%     specifically mentioned in the GUI use of conn.
%
%   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%   +     If resting state (no experimental conditions) enter a       +
%   +     single condition with onset 0 seconds and duration the      +
%   +     complete duration of each session.                          +
%   +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
%
% 2). Time series of each specified ROI is extracted. Other covariates are
%     defined by user.
% 3). Remove noise variance using aCompCor, realignment functional image to
%     structural image. Remove task- and/or session-related effects. Band
%     pass filter (specified by user). Detrending and despiking.
% 3). First level analysis ('type' chosen by user, or default bivariate
%     Pearson correlation). Time series within each session is weighted by
%     an HRF like weighting (or other weight type chosen by the user). 
%     According to the BATCH documentation, the advantage of HRF like 
%     weighting is to reduce the contribution of the first few scans, 
%     presumably during which period the subject is settling in and adapt 
%     to the scanner noise, etc.


% default output file types
global outtypes;
if isempty(outtypes)
    outtypes = [0 1 1 0 1];
end

% Parse optional inputs
flag = ParseOptionalInputs(varargin,...
    {'TR',3},{'filter',[0,Inf]},{'overwrite',true(1,3)},...
    {'done',true(1,3)},{'detrend',true},...
    {'despike',false},{'conn_type',1},{'ana_type',2},{'acq',1},...
    {'weight',2},{'num',1});
flag.overwrite = cell2struct(num2cell(flag.overwrite),{'Setup','Preprocessing','Analysis'},2);
flag.done = cell2struct(num2cell(flag.done),{'Setup','Preprocessing','Analysis'},2);

% ========================== Initialize ==================================
BATCH.filename = save_conn;
% Smoothing kernel
% BATCH.New.fWHM = 2;
% Specify functional volumes
if ischar(P),P = {P};end
% BATCH.New.functionals{1} = P;
% % Specify anatomical/structural image
% BATCH.New.structurals{1} = S;
% % Specifying image processing steps
% BATCH.New.steps = {'coregistration','segmentation','initialization'};
% % Voxel size
% BATCH.New.VOX = 1;
% % specifying TR
% BATCH.New.RT = flag.TR;

% ========================== Setup =======================================
% number of subjects
BATCH.Setup.nsubjects=1;       
% Perform native space analysis
BATCH.Setup.normalized = false;
% Set as new job
BATCH.Setup.isnew = true;
% specifying TR
BATCH.Setup.RT = flag.TR;
% Specifying processed functional images
BATCH.Setup.functionals{1} = P;%{AddPrefix(P,BATCH.New.steps)};
% Specifing anatomical/srtructural image
BATCH.Setup.structurals{1} = S;
% Specify binary mask
if myfieldexist(M,'Bin.files'),BATCH.Setup.voxelmaskfile = M.Bin.files;end
if myfieldexist(M,'Bin.res'),BATCH.Setup.voxelresolution = M.Bin.res;end
% Specify tissue mask
M = ParseMask(M);%fill in some empty field in the tissue mask
BATCH.Setup = mycopyfields(M,BATCH.Setup,...
    {'Grey.files','Grey.dimensions','White.files','White.dimensions',...
    'CSF.files','CSF.dimensions'},...
    {'masks.Grey.files','masks.Grey.dimensions','masks.White.files',...
    'masks.White.dimensions','masks.CSF.files','masks.CSF.dimensions'});
% Specify ROI
ROI = ParseROI(ROI);%fill in some empty field in the ROI structure
BATCH.Setup = mycopyfields(ROI,BATCH.Setup,...
    {'names','files','dimensions'},...
    {'rois.names','rois.files','rois.dimensions'});
% Set up conditions: Onset 0, duration = NumVols * TR, name = 'REST'
% Alternative, specify SPM.mat file (not implemented)
%BATCH.Setup.spmfiles = flag.SPM;
% Set up acquisition type: continuous vs. sparse (breaks within session)
BATCH.Setup.acquisitiontype = flag.acq;
% Specify First level output
outtypes(3) = outtypes(3)&flag.ana_type==2&any(flag.conn_type==[1,2]);
outtypes(4) = outtypes(4)&flag.ana_type==2&any(flag.conn_type==[1,2]);
outtypes(5) = outtypes(5)&flag.ana_type==2&any(flag.conn_type==[1,2]);
BATCH.Setup.outputfiles = outtypes;
% Specify conditions
BATCH.Setup.conditions.names = cellstr(repmat('REST',length(P),1));
if length(P)>1
    BATCH.Setup.conditions.names = cellfun(@(x,y) [x,num2str(y)],...
        BATCH.Setup.conditions.names,num2cell(1:length(P))','un',0);
end
BATCH.Setup.conditions.onsets{1}{1}(1:length(P)) = num2cell(zeros(1,length(P)));
BATCH.Setup.conditions.durations{1}{1}(1:length(P)) = num2cell(...
    BATCH.Setup.RT*cellfun(@(x) size(x,1),P).*ones(1,length(P)));
% Set up covariates
BATCH.Setup = mycopyfields(R,BATCH.Setup,...
    {'names','files'},{'covariates.names','covariates.files'});
% Overwrite option
BATCH.Setup.overwrite = flag.overwrite.Setup;
% Finishing the Setup
BATCH.Setup.done = flag.done.Setup;

% ========================== Additional Setups ===========================
% conn_batch(BATCH);
% global CONN_x;
% CONN_x.Setup.extractSVD = true;
% conn save;

% ========================== Preprocessing ===============================
% Frequency filter the data
BATCH.Preprocessing.filter = flag.filter;
% Detrending
BATCH.Preprocessing.detrending = flag.detrend;
% Despiking
BATCH.Preprocessing.despiking = flag.despike;
% Set up Confounds
BATCH.Preprocessing.confounds.names = [{'White Matter','CSF'},R.names];
BATCH.Preprocessing.confounds.dimensions = [{M.White.cutoff,M.CSF.cutoff},R.dimensions];
BATCH.Preprocessing.confounds.deriv = [{0,0},R.deriv];
% Overwrite option
BATCH.Preprocessing.overwrite = flag.overwrite.Preprocessing;
% Finishing Preprocessing
BATCH.Preprocessing.done = flag.done.Preprocessing;

% ======================= First level connectivity =======================
if flag.ana_type == 3,flag.num = 0;end
BATCH.Analysis.analysis_number = flag.num;
% Analysis type
BATCH.Analysis.type = flag.ana_type;
% Connectivity type
if any(flag.ana_type == [1,2]) && isnumeric(flag.conn_type)
    BATCH.Analysis.measure = flag.conn_type;
elseif flag.ana_type == 3 && isstruct(flag.conn_type)
    BATCH.Analysis.measures = flag.conn_type;
end
% Volume weight
BATCH.Analysis.weight = flag.weight;
% Set ROIs
BATCH.Analysis = mycopyfields(ROI,BATCH.Analysis,...
    {'names','dimensions','deriv'},...
    {'sources.names','sources.dimensions','sources.deriv'});
% Overwrite option
BATCH.Analysis.overwrite = flag.overwrite.Analysis;
% Finishing connectivity analysis
BATCH.Analysis.done = flag.done.Analysis;

% ====================== Run the analysis ================================
%conn_batch(BATCH);
end

%% sub-routines
function [TF,S] = myfieldexist(S,F)
%check if my field names exist
if isempty(S)
    TF = false;
    S = [];
    return;
end
F = regexp(F,'(\.)','split');
TF = 1;
for n = 1:length(F)
    TF = TF & isfield(S,F{n});
    if TF == 1
        S = S.(F{n});
    else
        S = [];
        return;
    end
end
TF = TF & ~isempty(S);
end

function S_out = mycopyfields(S_in,S_out,F_in,F_out)
% copy spcified field name from S_in to S_out
for n = 1:length(F_in)
    % check if field exists
    if ~myfieldexist(S_in,F_in{n})
        continue;%skip unspecified field
    end
    eval(['S_out.',F_out{n},' = S_in.',F_in{n},';']);
end
end

function M_out = ParseMask(M_in)
%sort out the mask structure
M_out = struct;
F = {'Grey','White','CSF'};
CUTOFF = {1,3,3};
DIM = {1,16,16};
for m = 1:length(F)
    [TF1,S1] = myfieldexist(M_in,[F{m},'.files']);
    [TF2,S2] = myfieldexist(M_in,[F{m},'.dimensions']);
    [TF3,S3] = myfieldexist(M_in,[F{m},'.cutoff']);
    if TF1
        M_out.(F{m}).files = S1;
    end
    if ~TF2
        M_out.(F{m}).dimensions = DIM{m};
    else
        M_out.(F{m}).dimensions = S2;
    end
    if ~TF3
        M_out.(F{m}).cutoff = CUTOFF{m};
    elseif TF3 && S3>S2
        M_out.(F{m}).cutoff = S2;
    else
        M_out.(F{m}).cutoff = S3;
    end
end
end

function Q = AddPrefix(P,give_proc)
% Image preprocessing steps and keys
PROC.steps = {'slicetiming','realignment','coregistration',...
    'segmentation','normalization','smoothing','initialization'};
PROC.prefix = {'a','r','r','','w',''};
IND = cell2mat(cellfun(@(x) find(ismember(PROC.steps,x),1),give_proc,'un',0));
if iscell(P),Q = cellstr(P{1});else Q = P;end
[PATHSTR,NAME,EXT] = cellfun(@fileparts,Q,'un',0);
NAME = cellfun(@(x) [cell2mat(PROC.prefix(IND)),x],NAME,'un',0);
Q = char(cellfun(@(x,y,z) fullfile(x,[y,z]),PATHSTR,NAME,EXT,'un',0));
end

function ROI = ParseROI(ROI)
if ~isfield(ROI,'dimensions');
    ROI.dimensions = num2cell(ones(1,length(ROI.names)));
end
if ~isfield(ROI,'deriv');
    ROI.deriv = num2cell(zeros(1,length(ROI.names)));
end
end

function [flag,ord]=ParseOptionalInputs(varargin_cell,varargin)
% reorganize varargin of current function to keyword and default_value
keyword = cell(1,length(varargin));
default_val = cell(1,length(varargin));
for k = 1:length(varargin)
    keyword{k} = varargin{k}{1};
    default_val{k} = varargin{k}{2};
end

% check if the input keywords matches the list provided
NOTMATCH = cellfun(@(x) find(~ismember(x,keyword)),varargin_cell(1:2:end),'un',0);
NOTMATCH = ~cellfun(@isempty,NOTMATCH);
if any(NOTMATCH)
    error('Unrecognized option(s):\n%s\n',...
        char(varargin_cell(2*(find(NOTMATCH)-1)+1)));
end

%place holding
flag=struct();
ord = [];

% assuming the structure of varargin_cell is {'opt1',val1,'opt2',val2,...}
for n = 1:length(keyword)
    IND=find(strcmpi(keyword(n),varargin_cell),1);
    if ~isempty(IND)
        flag.(keyword{n})=varargin_cell{IND+1};
    else
        flag.(keyword{n})=default_val{n};
    end
end

%in case there is only one search keyword, return the value
if length(keyword)==1
    warning off;
    flag=flag.(keyword{1});
    warning on;
end
end
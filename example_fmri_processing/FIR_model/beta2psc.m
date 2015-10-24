function PSC = beta2psc(SPM, ROI_loc,algorithm_type,varargin)
% PSC = beta2psc(input_signal,signal_type,SPM,...)
% convert beta values to percent signal change
% 
% Required Inputs:%       
%       SPM: spm's SPM.mat file
%       ROI_loc: location of ROI file, can be either a MarsBaR ROI object
%                or a nifti file containing the ROI cluster
%       algorithm_type: 'marsbar'|'stanford'
%               'marsbar', refer to: http://marsbar.sourceforge.net/faq.html
%               'stanford', refer to: http://cibsr.stanford.edu/documents/FMRIPercentSignalChange.pdf
%
%
% PSC = beta2psc(SPM, ROI_loc, 'marsbar', bin_size,fir_length)
%       bin_size: bin size of FIR, in seconds, usually TR
%       fir_length: length of FIR, in seconds
%
% MarsBaR is Required
%
%    The returned PSC structure will have the following fields:
%               event_names: name of each event in cell array
%               event_type_names: type of events, or unique(event_names)
%               psc_ev: mean percent signal change of each event
%               fir_tc: time course of FIR, bin_size x length(event_names)
%               fir_tc_averaged: time course of FIR, averaged across the
%                                same events, with dimension 
%                                bin_size x length(event_type_names)
%               marsS: general stats of the ROI for all contrasts
%               beta_values: beta values of the ROI from all beta images 
%
% 
% PSC = beta2psc(SPM, ROI_loc, 'stanford') (Not Implemented)
%

% Find necessary parameters for calculation

switch algorithm_type
    
    case {'marsbar'}
        %bin_size=tr(E);%2seconds
        %fir_length=12
        %bin_size = varargin{1};%otherwise, bin_size = length of tr;
        %fir_length = varargin{2};
        if varargin{1}>varargin{2}
            error('bin_size cannot be longer than fir_length');
        end
        PSC = beta2psc_marsbar(SPM,ROI_loc,varargin{1},varargin{2});
        
     
    case {'stanford'}
        % reveal SPM design matrix
        spm_DesRep('DesMtx', SPM.xX, vertcat({SPM.xY.VY.fname}'), SPM.xsDes)
        % according to Stanford's documentation, the following formula are
        % most accurate when the design is either slow event related design
        % or block design. The calcualted percent signal change will be
        % underestimating the effect of the event if the design is fast
        % event related.
        switch signal_type
            case {'con'}
                psc_vect = (input_signal/contrastsum)*(PEAK/BMEAN)*100;
            case {'beta'}
                psc_vect = input_signal*(PEAK/BMEAN)*100;
                
        end
   
end
end
        

% internal functions for each method
function PSC = beta2psc_marsbar(SPM,ROI_loc,bin_size,fir_length)
%add marsbar path
%addpath(('/home/cui/scripts/jong_spm8/'));
%addpath(genpath('/home/cui/scripts/marsbar/'));
% Make marsbar design object from SPM
D = mardo(SPM);
% Inspect what ROI_loc is referring to
[~,~,ext] = fileparts(ROI_loc);
switch ext
    case {'.nii','.img','.hdr'}%nifti file / image cluster
        % convert nifti image ROI to marsbar ROI object
        %note: original mars_img2rois will only save the roi to a
        %directory, whereas this customized version will store the
        %created ROI in memory
        R=customized_mars_img2rois(ROI_loc,'i');
    case {'.mat'}%marsbar ROI object
        % if suspected to be a marsbar object, use marsbar
        % built-in function to load the ROI
        R = maroi(ROI_loc);
end
% get mean from ROI
Y = get_marsy(R,D,'mean');
% get contrast from original design
%xCon = get_contrasts(D);
% Estimate design on ROI data
E = estimate(D,Y);
% put contrasts from original design back into design object
% E = set_contrasts(E, xCon);
% get design betas
PSC.beta_values = betas(E);
% get stats for all contrasts
% PSC.marsS = compute_contrasts(E, 1:length(xCon));
% get definition of all events in the model
[e_specs, e_names] = event_specs(E);
n_events = size(e_specs,2);
dur = 0;% for event related design, duration = 0
PSC.psc_ev = zeros(1,n_events);
% Return percent signal estimate for all events in design
for e_s = 1:n_events
    PSC.psc_ev(e_s) = event_signal(E, e_specs(:,e_s),dur);
end
%store corresponding event names in the PSC structure
PSC.event_names = e_names;

% Calculate FIR for each event (with duplicated events)
% Bin size in seconds for FIR
if isempty(bin_size)
    bin_size = tr(E);
end
%         % Length of FIR in seconds
%         fir_length = 12;
% Number of FIR time bins to cover length of FIR
bin_no = fir_length / bin_size;
% Options -here 'single' FIR model, removing all durations and
% return estimated in percent
opts = struct('single',1,'percent',1);
% Return time courses for all events of each run in fir_tc matrix
PSC.fir_tc = zeros(bin_no,n_events);
for e_s = 1:n_events
    PSC.fir_tc(:,e_s) = event_fitted_fir(E, e_specs(:,e_s),...
        bin_size, bin_no, opts);
end

% Calculate FIR by averaging event of the same type (without
% duplicated events)
% Get compound event types structure
ets = event_types_named(E);
n_event_types = length(ets);
PSC.fir_tc_averaged = zeros(bin_no, n_event_types);
for et = 1:n_event_types
    PSC.fir_tc_averaged(:,et) = event_fitted_fir(E,...
        ets(et).e_spec,bin_size,bin_no,opts);
end
% store type of events
PSC.event_type_names = {ets.name};
% sort the fieldnames
PSC = orderfields(PSC);
end

% customized version of mars_img2rois, will return ROI object to the memory
function o=customized_mars_img2rois(P, flags)
% creates ROIs from cluster image or image containing ROIs defined by unique nos
% FORMAT mars_img2rois(P, flags)
%
% P       - image (string or struct) path
% flags   - none or more of: [default = 'i']
%             'i' - id image, voxel values identify ROIs. Works for
%                   discrete clusters of ROIs
%             'c' - cluster image, clusters identified by location
%                   Can only load one cluster of ROI. Fails when there are
%                   multiple clusters.
%             'x' - label clusters by location of maximum 
%                   (default is location of centre of mass)
%
% $Id$
  
if nargin < 1
  P = '';
end
if nargin < 2
  flags = ' ';
end

% use the file name as ROI object name prefix
[~,rootn,~] = fileparts(P);

% Process input arguments
if any(flags == 'i')
  Pprompt = 'Image containing ROI ids';
else
  Pprompt = 'Image containing clusters';
end
if isempty(P)
  P = spm_get(1, mars_veropts('get_img_ext', Pprompt));
end
if isempty(P)
  return
end
if ischar(P)
  P = spm_vol(P);
end

if isempty(flags)
  flags = 'i';  % id image is default
end

% read img, get non-zero voxels
img = spm_read_vols(P);
img = img(:)';
dim = P.dim(1:3);
pts = find(img~=0);

% e2xyz
nz = pts-1;
pl_sz = dim(1)*dim(2);
Z = floor(nz / pl_sz);
nz = nz - Z*pl_sz;
Y = floor(nz / dim(1));
X = nz - Y*dim(1);
XYZ = [X; Y;Z] +1;

% collect clusters
vals = img(pts);

% select cluster or id 
if any(flags == 'i')
  cl_vals = vals;
else
  cl_vals = spm_clusters(XYZ);
end

for c = unique(cl_vals)
  % points for this region/cluster
  t_cl_is = find(cl_vals == c);

  % corresponding XYZ
  cXYZ = XYZ(:, t_cl_is);
  
  if ~isempty(cXYZ)
    % location label for cluster images
    if any(flags == 'c')
      if any(flags == 'x') % maximum 
	[mx maxi] = max(vals(t_cl_is));
	mi = t_cl_is(maxi);
	% voxel coordinate of max
	vco = XYZ(:, mi);
      else % centre of mass
	vco = mean(cXYZ, 2);
      end
    
      % pt coordinates in mm
      pt_lab = P.mat * [vco; 1];
      pt_lab = pt_lab(1:3);

      % file name and labels
      d = sprintf('%s cluster at [%0.1f %0.1f %0.1f]', rootn, pt_lab);
      l = sprintf('%s_%0.0f_%0.0f_%0.0f', rootn, pt_lab);
      
    else % id image labels from voxel values
      % file name and labels
      d = sprintf('%s: id: %d', rootn, c);
      l = sprintf('%s_%d', rootn, c);
    end

    o = maroi_pointlist(struct('XYZ',cXYZ,...
			       'mat',P.mat,...
			       'descrip',d,...
			       'label', l), ...
			'vox');
  end
end
end




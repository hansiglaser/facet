%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cleaning example 1
%
%  Copyright (c) 2010-2012 Johann Glaser <Johann.Glaser@gmx.at>
%
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; either version 2
% of the License, or (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, 
% MA  02110-1301, USA.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Note: This only works with the EEG dataset supplied by Niazy with the
% EEGLAB plugin.
%
function EEGout = CleanEx1(EEGin)

  %%%% Create object
  E = FACET.FACET_Text();

  %%%% Set Input Parameters
  %%% EEGLAB EEG data structure
  E.EEG = EEGin;

  % List channels which should not be processed
  E.ExcludeChannels = [];

  %%% Triggers from MR device
  % If the triggers are slice triggers, set to true. Volume / section
  % triggers are assumed if set to false (default).
  E.SliceTrigger = true;
  % Relative position of trigger within artifact (slice/volume):
  % 0 for exact start -> 1 for exact end, default=0.03;
  E.RelTrigPos = 0.03;
  % Automatically determine the exact start of the first artifact
  E.AutoPreTrig = false;
  % Set to true if your data has volume gaps or false if not. Let it
  % unset to use auto-detection. Volume gaps are breaks between the
  % acquisition of two volumes.
  E.VolumeGaps = [];
  % The (estimated) artifact signal during volume gaps is unknown, so
  % this (short) periods will be 0.0. If InterpolateVolumeGaps is true,
  % the period will be filled with a linear interpolation of the values
  % before and after the gap.
  % Note this is different from the processing step "RemoveVolumeArt',
  % which replaces the data during the volume gap with an interpolated
  % function and subtracts an estimated volume artifact from the
  % neighbouring slices.
  E.InterpolateVolumeGaps = true;
  % Specify the slice index used by RAAlignSlices and RAAlignSubSample
  % as reference to which all other slices are aligned. The range is 1
  % to the total number of slices.
  E.AlignSlicesReference = 1;

  %%% Averaging of artifacts
  % Length of averaging window in number of artifacts
  E.AvgWindow = 30;

  %%% Pre-Filter EEG data
  % Filter the EEG data before any other processing. The filter can be
  % a low-pass, high-pass or combination of both as well as a custom
  % filter specified with weights.
  % Low-Pass-Filter:
  %  - If left empty, no low-pass will be applied.
  %  - If a single frequency is specified, this applies to all channels.
  %    A frequency of 0.0 means no filter for this channel.
  %  - If a vector of frequencies is specified, every number corresponds
  %    to a channel.
  %E.PreFilterLPFrequency = 100;
  % High-Pass-Filter (same types apply). If you want a very low cut-off
  % frequency, the sharp edge of this filter will introduce ringing.
  % Consider using PreFilterGaussHPFrequency below.
  %E.PreFilterHPFrequency = 1;
  % The filter is implemented in frequency domain, i.e. multiplication of
  % its transfer function. The transfer function is specified as a
  % piecewise linear function with frequency and amplitude points, as
  % also used for functions like firls().
  %  - If left empty, the values are calculated from PreFilterLPFrequency
  %    and PreFilterHPFrequency.
  %  - If set to two single-row vectors, they specify the transfer
  %    function for all channels.
  %  - If set to a cell array, each cell gives the transfer function
  %    points for the corresponding channel.
  %E.PreFilterHFrequencies = [];
  %E.PreFilterHAmplitudes  = [];
  % This special pre-processing filter has a Gauss'ian transfer function,
  % which has the maximum steepness without ringing. The filter is
  % applied in addition to the above one. The same types as above apply.
  E.PreFilterGaussHPFrequency = 1.0;

  %%% Artifact Removal Steps
  % This cell array specifies the steps performed for every channel to
  % remove the artifact. It can contain strings to specify methods
  % provided by this class, i.e. 'Cut' will perform RACut(). Please care
  % for the method descriptions as they have some mutual dependencies.
  %
  % Additionally you can specify function handles. These must accept
  % three parameters:
  %  1) object handle to this instance,
  %  2) index of the position in this sequence (starting by 1)
  %  3) channel number
  E.RASequence = {
    'Cut',...
    'UpSample',...
    'AlignSlices',...
    'AlignSubSample',...
    'RemoveVolumeArt',...
     @FACET.AvgArtWghtFARM,...
    'CalcAvgArt',...
    'PCA',...
    'DownSample',...
    'Paste',...
    'LowPass',...
    'ANC' };

  %%% Interpolation
  % Interpolation factor, unset -> no interpolation
  E.Upsample = 10;
  % Cutoff frequency (relative to the sampling rate) assumed by
  % interp(). Do not modify this value unless you know what you do!
  E.UpsampleCutoff = 0.5;

  %%% Sub-Sample Alignment
  % High-Pass cut-off frequency, set to 0 or [] to disable the HP
  E.SSAHPFrequency = 300;

  %%% Optimal Basis Set (OBS) from PCA
  % Number of principal components to use in OBS. Set to 0 to skip this
  % step, set to 'auto' to determine the optimal number automatically
  % (default).
  E.OBSNumPCs = 'auto';
  % Channels not to perform OBS on
  E.OBSExcludeChannels=[31 32];
  % High pass cutoff frequency applied before PCA
  E.OBSHPFrequency = 300;

  %%% Low Pass after artifact removal (but before ANC)
  % Filter cutoff frequency, unset -> no low-pass is applied. If left
  % unset and ANC is enable, it will be set to ANCDefaultLP.
  E.FinalLPFrequency = 70;

  %%% Adaptive Noise Cancellation (ANC)
  % Set to true to enable ANC
  E.DoANC = true;

  %%% Processing of data outside of fMRI acquisition
  % Set to true to keep the data outside of the fMRI acquisition (i.e.
  %   the beginning and the end of the data) as is.
  % Set to false to use the full output of the algorithm, even outside
  %   of the fMRI acquisition area.
  E.DontTouchNonArtifact = false;

  %%% Execution Options
  % Profiling: print runtime information of every step
  E.Profiling = false;

  %%%% Perform Artifact Removal
  % FINDTRIGGERS  Find triggers in EEG.event matching EventType
  %
  % EventType
  %   Type of trigger event to use for artifact synchronization. All
  %   events which EEG.event.type matches EventType are used. If left
  %   unset, all events are used.
  %   To get a list of all event types try
  %     unique({EEG.event.type})
  % TriggerOffset
  %   Offset of trigger times. The value of this variable is added to the
  %   values taken from EEG.event.latency. If the trigger events from the
  %   original data set are too late, you have to put a negative number
  %   here.
  E.FindTriggers('slice',0);

  % ANALYZEDATA  Analyze EEG dataset and your setup
  %
  % Analyze EEG dataset and print information.
  %
  % This function can be used as soon obj.EEG is assigned. It will give
  % more information after FindTriggers() was used.
  %E.AnalyzeData;

  % FINDMISSINGTRIGGERS  Find missing triggers
  %
  % Use this methods if some triggers during the acquisition are missing.
  %
  % Important: This function can only find triggers which are between the
  % first and the last triggers as denoted by EEG.event. It doesn't add
  % triggers before the first and after the last.
  %
  % Volumes
  %   Total number of fMRI volumes withing EEG.event.
  % Slices
  %   fMRI slices per volume. Set to 1 if FindTriggers was used for
  %   volume triggers.
  E.FindMissingTriggers(40,21);

  % ADDTRIGGERS  Add triggers outside of defined trigger range
  %
  % Use this method if some triggers before the first or after the last
  % are missing.
  %
  % Where
  %   Sample indices into EEG.data to add to the trigger array.
  %E.AddTriggers(...);   % not necessary here

  % GENERATESLICETRIGGERS  Convert volume triggers to slice triggers
  %
  % This function should be called after all volume triggers are setup
  % using the functions FindTriggers(), FindMissingTriggers() and
  % AddTriggers().
  %
  % All internally stored trigger indices are replaced by the newly
  % generated slice trigger indices.
  %
  % Slices
  %   Number of slices per volume, must be integer.
  % Duration
  %   Slice duration in sampling units, can be float.
  % RelPos
  %   Relative position of the first slice trigger of each volume to the
  %   volume trigger. 0.0 means that the first slice trigger is at the
  %   position of the volume trigger, 1.0 means the first slice trigger
  %   is one slice-periode before the volume trigger and the second
  %   slice trigger is at the volume trigger. 0.5 means that the first
  %   and the second volume trigger are centered around the volume
  %   trigger.
  %E.GenerateSliceTriggers(...);  % not necessary here

  % CHECKDATA  Check EEG dataset and your setup
  %
  % Check EEG dataset and your setup for any notable or problematic
  % conditions.
  %
  E.CheckData;

  E.Prepare;

  %E.AvgMatrix = FACET.AvgArtWghtSliceTrigger(E);
  %E.AvgMatrix = FACET.AvgArtWghtVolumeTrigger(E);
  %E.AvgMatrix = FACET.AvgArtWghtCorrespondingSlice(E,E.MRSlices);
  %E.AvgMatrix = FACET.AvgArtWghtMoosmann(E,'example01.txt',0.8);
  % calculate AvgMatrix for every channel separately, see RASequence above
  E.AvgMatrixUpdaterData.SearchHalfWindow = 3*E.HalfWindow;

  E.PreFilter;

  E.RemoveArtifacts;

  E.Finish;

  %%%% Return parameters
  EEGout = E.EEG;

end

% Was macht van der Meer anders?
%  + 30Hz HP 24dB/Oct., "low-frequency EMG signal contents can be regained y rectification"
%  - slice-marker insertion (because their scanner only gives volume markers)
%  - use channel with largest artifact to determine slice-markers, assume identical timing information for other channels
%  - slice vs. volume
%  - optimize timing parameters for slice duration and inter-volume-delay
%  + sub-sample-alignment
%  - replace inter-volume-stuff with synthesized data, note: the volume artifact overlaps a bit with the slices before and after it!
%  + large sliding window (50) and use only (12) best slice-artifacts
%  + PCA: (max?) 4 (Niazy angeblich 4-8):

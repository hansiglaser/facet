%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cleaning example 6
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
% Note: This example uses the pilot dataset supplied by Fischi and performs
% a configurable artifact removal algorithm stepwise improving from Niazy's
% EEGLAB plugin to our full extent.
%
% The MR acquisition was performed with a 3T Siemens TIM Trio scanner using
% a 32-channel head coil. The parameters of the echo planar imaging (EPI)
% sequence were volume repetition time of TR=2s with 25 axial slices per
% volume and a slice time of 80ms (12.5Hz). The sequence does not have an
% inter-volume gap. Each slice consists of a 128x128 matrix. A total of 150
% volumes were recorded which results in 5 minutes of acquisition.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Results printed by AnalyzeData():
%
% Samples:       648986
% Sampling Rate: 2000
% Duration:      324.4930s (5 minutes 24.5 seconds)
% Channels:      22
%    1-10: Emg1 Emg2 Emg3 Emg5 Fz Emg4 Emg6 Emg7 Emg9 Emg8
%   11-20: Emg10 Cz Pz HR ECG LatFrontalis CorrSupcilii OrbiOcculi ZygomMajor Masseter
%   21-22: VEOG HEOG
% Events:
%   'IA'        3825x
%   'PD'         250x
%   'pulse'      150x
% Acquisition
%   approx. begin:      12259  (   6.13s)
%   approx. end:       639290  ( 319.64s)
%   approx. duration:  627032  ( 313.52s)
% Non-Acquisition
%   approx. before:     12258  (   6.13s)
%   approx. after:       9695  (   4.85s)
%   approx. total:      21953  (  10.98s)
% Trigger Distances Histogram
%    159 (79.50ms):    94x #
%    160 (80.00ms):  3583x ########################################################
%    161 (80.50ms):   147x ##
% WARNING: Comparing mean triggers difference with total acquisition duration
%   suggests that triggers are missing (have: 3825, approx. required: 3918.61)
%   Try FindMissingTriggers() and AddTriggers.
% Mean trigger distances 80.01ms are less than 1.0s, assuming SLICE triggers.
% Small variation of trigger distances. No volume gaps assumed.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function EEGout = CleanEx6(EEGin,varargin)

  %%%% Mode parameter processing
  DoPreFilter          = false;
  DoAlignSubSample     = false;
  DoRemoveVolumeArt    = false;
  DoAvgArtWghtFARM     = false;
  DoInterpolateVolGaps = false;
  DoPCA                = false;
  DoLowPass            = false;
  DoANC                = false;
  DoFilterNonArtifact  = false;
  DoUpsample1          = false;
  DoAllen              = false;
  for arg = varargin
    if     strcmp(arg,'PreFilter')
      DoPreFilter          = true;
    elseif strcmp(arg,'AlignSubSample')
      DoAlignSubSample     = true;
    elseif strcmp(arg,'RemoveVolumeArt')
      DoRemoveVolumeArt    = true;
    elseif strcmp(arg,'AvgArtWghtFARM')
      DoAvgArtWghtFARM     = true;
    elseif strcmp(arg,'InterpolateVolGaps')
      DoInterpolateVolGaps = true;
    elseif strcmp(arg,'PCA')
      DoPCA                = true;
    elseif strcmp(arg,'LowPass')
      DoLowPass            = true;
    elseif strcmp(arg,'ANC')
      DoANC                = true;
    elseif strcmp(arg,'FilterNonArtifact')
      DoFilterNonArtifact  = true;
    elseif strcmp(arg,'Upsample1')
      DoUpsample1          = true;
    elseif strcmp(arg,'Allen')
      % performs an artifact removal algorithm modeled after
      % Allen et al. (2000).
      % Don't use the options "RemoveVolumeArt", "AvgArtWghtFARM",
      % "PreFilter", "PCA", "FilterNonArtifact"
      % CleanEx4.m uses "InterpolateVolGaps"
      % Use "Upsample1" as an additiona option for pre-processing
      % Use "LowPass" and "ANC" as additional options for post-processing.
      DoAllen              = true;
    else
      error('CleanEx6:Mode','Invalid mode parameter "%s"',arg);
    end
  end

  %%%% Create object
  E = FACET.FACET_Text();

  %%%% Set Input Parameters
  %%% EEGLAB EEG data structure
  E.EEG = EEGin;

  % List channels which should not be processed
  E.ExcludeChannels = [14,15]; % exclude HR and ECG

  %%% Triggers from MR device
  % If the triggers are slice triggers, set to true. Volume / section
  % triggers are assumed if set to false (default).
  E.SliceTrigger = true;
  % Relative position of trigger within artifact (slice/volume):
  % 0 for exact start -> 1 for exact end, default=0.03;
  E.RelTrigPos = 0.0;
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
  E.InterpolateVolumeGaps = DoInterpolateVolGaps;
  % Specify the slice index used by RAAlignSlices and RAAlignSubSample
  % as reference to which all other slices are aligned. The range is 1
  % to the total number of slices.
  E.AlignSlicesReference = 38;

  %%% Averaging of artifacts
  % Length of averaging window in number of artifacts
  if DoAllen
    E.AvgWindow = 25;
  else
    E.AvgWindow = 30;
  end

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
  if DoPreFilter
    E.PreFilterGaussHPFrequency = 1.0;
  end

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
  E.RASequence = { };
  E.RASequence = { E.RASequence{:} 'Cut' };
  E.RASequence = { E.RASequence{:} 'UpSample' };
  E.RASequence = { E.RASequence{:} 'AlignSlices' };
  if DoAlignSubSample
    E.RASequence = { E.RASequence{:} 'AlignSubSample' };
  end
  if DoRemoveVolumeArt
    % no volume gaps, but still volume artifacts!
    E.RASequence = { E.RASequence{:} 'RemoveVolumeArt' };
  end
  if DoAvgArtWghtFARM
    % use AvgArtWghtFARM like [Mee10]
    E.RASequence = { E.RASequence{:}  @FACET.AvgArtWghtFARM };
  elseif DoAllen
    % use AvgArtWghtAllen like [All00]
    E.RASequence = { E.RASequence{:}  @FACET.AvgArtWghtAllen };
  else
    % use AvgArtWghtSliceTrigger like [Niazy2005]
    % one comman AvgMatrix for all channels, see below
  end
  E.RASequence = { E.RASequence{:} 'CalcAvgArt' };
  if DoPCA
    E.RASequence = { E.RASequence{:} 'PCA' };
  end
  E.RASequence = { E.RASequence{:} 'DownSample' };
  E.RASequence = { E.RASequence{:} 'Paste' };
  if DoLowPass
    E.RASequence = { E.RASequence{:} 'LowPass' };
  end
  if DoANC
    E.RASequence = { E.RASequence{:} 'ANC' };
  end

  %%% Interpolation
  % Interpolation factor, unset -> no interpolation
  E.Upsample = 10;
  % Cutoff frequency (relative to the sampling rate) assumed by
  % interp(). Do not modify this value unless you know what you do!
  if DoUpsample1
    E.UpsampleCutoff = 1.0;
  else
    E.UpsampleCutoff = 0.5;
  end

  %%% Sub-Sample Alignment
  % High-Pass cut-off frequency, set to 0 or [] to disable the HP
  E.SSAHPFrequency = 300;

  %%% Optimal Basis Set (OBS) from PCA
  % Number of principal components to use in OBS. Set to 0 to skip this
  % step, set to 'auto' to determine the optimal number automatically
  % (default).
  E.OBSNumPCs = 'auto';
  % Channels not to perform OBS on
  E.OBSExcludeChannels=[14 15 21 22];
  % High pass cutoff frequency applied before PCA
  E.OBSHPFrequency = 300;

  %%% Low Pass after artifact removal (but before ANC)
  % Filter cutoff frequency, unset -> no low-pass is applied. If left
  % unset and ANC is enable, it will be set to ANCDefaultLP.
  %
  % [All00] used an 80Hz low-pass after down-sampling followed by a 80Hz
  % low-pass. We keep 70Hz here to avoid unfair comparison results.
  E.FinalLPFrequency = 70;

  %%% Adaptive Noise Cancellation (ANC)
  % Set to true to enable ANC
  E.DoANC = true;

  %%% Processing of data outside of fMRI acquisition
  % Set to true to keep the data outside of the fMRI acquisition (i.e.
  %   the beginning and the end of the data) as is.
  % Set to false to use the full output of the algorithm, even outside
  %   of the fMRI acquisition area.
  if DoFilterNonArtifact
    E.DontTouchNonArtifact = false;
  else
    E.DontTouchNonArtifact = true;
  end

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
  E.FindTriggers('IA',-1550-21);

  % ANALYZEDATA  Analyze EEG dataset and your setup
  %
  % Analyze EEG dataset and print information.
  %
  % This function can be used as soon obj.EEG is assigned. It will give
  % more information after FindTriggers() was used.
  E.AnalyzeData;

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
  E.FindMissingTriggers(153,25);

  % CHECKDATA  Check EEG dataset and your setup
  %
  % Check EEG dataset and your setup for any notable or problematic
  % conditions.
  %
  E.CheckData;

  E.Prepare;

  if DoAvgArtWghtFARM
    % use AvgArtWghtFARM like [Mee10]
    % calculate AvgMatrix for every channel separately, see RASequence above
    E.AvgMatrixUpdaterData.SearchHalfWindow = 3*E.HalfWindow;
  elseif DoAllen
    % use AvgArtWghtAllen like [All00]
    % calculate AvgMatrix for every channel separately, see RASequence above
    E.AvgMatrixUpdaterData.SearchHalfWindow = 3*E.HalfWindow;
  else
    % use AvgArtWghtSliceTrigger like [Niazy2005]
    % one comman AvgMatrix for all channels
    E.AvgMatrix = FACET.AvgArtWghtSliceTrigger(E);
  end

  if DoPreFilter
    E.PreFilter;
  end

  E.RemoveArtifacts;

  E.Finish;

  %%%% Return parameters
  EEGout = E.EEG;

end

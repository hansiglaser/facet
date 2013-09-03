%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Cleaning example 3
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
% Note: This only works with the EEG dataset from Aachen
%
%  - 64 channels: Fp1, Fp2, F3, F4, C3, C4, P3, P4, O1, O2, F7, F8, T7, T8,
%    P7, P8, Fz, Cz, Pz, Oz, FC1, FC2, CP1, CP2, FC5, FC6, CP5, CP6, TP9,
%    TP10, POz, ECG, F1, F2, C1, C2, P1, P2, AF3, AF4, FC3, FC4, CP3, CP4,
%    PO3, PO4, F5, F6, C5, C6, P5, P6, AF7, AF8, FT7, FT8, TP7, TP8, PO7,
%    PO8, FT9, FT10, Fpz, CPz
%  - 3762000 points (3.7 million, 752.4 sec)
%  - total 963MB
%  - srate = 5000 Sps
%  - minimum value: -16.384E3 µV
%  - maximum value: +16.384E3 µV
%  - starting with 7.165 seconds (index 35828) without acquisition
%  - acqisition ends at approx. 751.1 sec (index 3755834)
%  - followed by approx. 1.2 sec without acquisition
%  - markers:   unique({EEG_Aachen.event.type})
%    'R128', 'S  1', 'S  2', 'S  3', 'S  4', 'S  5', 'S  6', 'S  7', 'S  8',
%    'S 11', 'S 13', 'S 14', 'S 15', 'S 16', 'S 17', 'S 18', 'S 71', 'S 72',
%    'S 91', 'S 93', 'S 95', 'S 97', 'S 99', 'Sync On', 'boundary'
%  - Regarding the mail from Fischi from Fri, 08 Jul 2011 14:28:15 +0200, the
%    volume marker is 'R128'.
%  - there are no slice markers
%  - total of 370 volumes with TR = 2000ms ->  0.5000Hz
%  - 33 slices per volume -> 60.60606060ms -> 16.5000Hz
%  - after the last volume marker there are only 32 slices -> volume marker
%    denotes quite the beginning of the first slice
%  - the first volume marker is within the 67th slice -> two volume markers
%    are missing
%
% EEG_Aachen-Ch1.png:
%   t=(0:EEG_Aachen.pnts-1)/EEG_Aachen.srate;
%   plot(t,EEG_Aachen.data(1,:));
% EEG_Aachen-Ch1-FFT.png:
%   F=fftshift(fft(EEG_Aachen.data(1,35829:3755834)));
%   f=(0:length(F)-1)/length(F)*EEG_Aachen.srate - EEG_Aachen.srate/2;
%   plot(f,abs(F));
% EEG_Aachen-Ch1-FFT-log.png:
%   semilogy(f,abs(F));
% EEG_Aachen-Ch1-FFT-log-dB.png:
%   plot(f,log10(abs(F)/max(abs(F)))*20);
%   xlabel('f (Hz)');
%   ylabel('dB');
%
% main component at 16.5000Hz, modulated with smaller components at
% +/- 0.5000 Hz, from 313.5Hz with -14.95dB to 1073Hz with -66.67dB a linear
% decrease of amplitude is visible. Above 1kHz, everything is well below -60dB
% referenced to the maximum amplitude.
% 
% -14 bis 1986, weil das erste Gradientenartefakt -14 ms vor dem ersten R128 anfaengt. 
% 
% TR=2000
% 
% EEG_Aachen-slice.png:
%   plot(t,EEG_Aachen.data(1,:));
%   hold on;
%   plot(t,EEG_Aachen.data(11,:),'r');
%   plot(t,EEG_Aachen.data(21,:),'g');
%   plot(t,EEG_Aachen.data(31,:),'m');
%   plot(t,EEG_Aachen.data(41,:),'c');
%   stem(trigs/EEG_Aachen.srate,5900*ones(1,length(trigs)),'k');
% channel 11 (red) shows readout gradient (others don't show that strong),
% counting waveform shows approx. 985.4 Hz
% EEG_Aachen-Ch11-FFT-log.png:
%   semilogy(f,abs(fftshift(fft(EEG_Aachen.data(11,35829:3755834)))),'r');
% the data curser is at 990.5 Hz at the highest peak near 985Hz.
%
function EEGout = CleanEx3(EEGin)

  %%%% Create object
  E = FACET.FACET_Text();

  %%%% Set Input Parameters
  %%% EEGLAB EEG data structure
  E.EEG = EEGin;

  % List channels which should not be processed
  E.ExcludeChannels = [32:64]; % exclude HR and ECG

  %%% Triggers from MR device
  % If the triggers are slice triggers, set to true. Volume / section
  % triggers are assumed if set to false (default).
  E.SliceTrigger = false;
  % Relative position of trigger within artifact (slice/volume):
  % 0 for exact start -> 1 for exact end, default=0.03;
  E.RelTrigPos = 0.1914;
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
     @FACET.AvgArtWghtFARM,...
    'CalcAvgArt',...
    'PCA',...
    'DownSample',...
    'Paste',...
    'LowPass',...
    'ANC' };

  %%% Interpolation
  % Interpolation factor, unset -> no interpolation
  E.Upsample = 4;   % data is already with 5kSps, upsample to 20kSps
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
  E.OBSExcludeChannels=[];
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
  E.Profiling = true;

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
  E.FindTriggers('R128',0);

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
  %
  % The Aachen dataset doesn't have missing triggers.
  %E.FindMissingTriggers(370,1);
  %E.FindMissingTriggers(372,1);
  %E.FindMissingTriggers(372,33);

  % ADDTRIGGERS  Add triggers outside of defined trigger range
  %
  % Use this method if some triggers before the first or after the last
  % are missing.
  %
  % Where
  %   Sample indices into EEG.data to add to the trigger array.
  E.AddTriggers([-2 -1] * mean(diff(E.Triggers)) + E.Triggers(1));

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
  %
  % 2.0000s per Volume, 33 slices per volume
  E.GenerateSliceTriggers(33,2.0/33.0*E.SamplingFrequency,0.0);

  E.AnalyzeData;

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

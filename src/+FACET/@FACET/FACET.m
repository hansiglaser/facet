%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FACET   Artifact removal algorithm for EEG and EMG recorded during
%   fMRI acquisition
%   This is the main class of the artifact removal algorithm.
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
% TODO:
%  - remove DoANC variable
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef FACET < handle
  % FACET Artifact removal algorithm for EEG and EMG recorded during
  %   fMRI acquisition
  %
  % for usage see CleanEx1.m
  %
  % This class doesn't print any status information but offers numerous
  % events. Use FACET_Text if you want status information.

  % public properties, should be set before executing the algorithms, but
  % most values have smart defaults
  properties(Access=public,Dependent)
    %%% EEGLAB EEG data structure
    % Note: This is implemented as a pair of getter/setter. Everything
    % inside of the algorithm uses the protected variable FEEG to avoid
    % the getter/setter overhead.
    EEG;
  end
  properties(Access=public)
    % List of channels which should not be processed
    ExcludeChannels;

    %%% Triggers from MR device
    % If the triggers are slice triggers, set to true. Volume / section
    % triggers are assumed if set to false (default).
    SliceTrigger = false;
    % Relative position of trigger within artifact (slice/volume):
    % 0 for exact start -> 1 for exact end, default=0.03;
    RelTrigPos = 0.03;
    % Automatically determine the exact start of the first artifact
    AutoPreTrig = true;
    % Set to true if your data has volume gaps or false if not. Let it
    % unset to use auto-detection. Volume gaps are breaks between the
    % acquisition of two volumes.
    VolumeGaps = [];
    % The (estimated) artifact signal during volume gaps is unknown, so
    % this (short) periods will be 0.0. If InterpolateVolumeGaps is true,
    % the period will be filled with a linear interpolation of the values
    % before and after the gap.
    % Note this is different from the processing step "RemoveVolumeArt',
    % which replaces the data during the volume gap with an interpolated
    % function and subtracts an estimated volume artifact from the
    % neighbouring slices.
    InterpolateVolumeGaps = true;
    % Specify the slice index used by RAAlignSlices and RAAlignSubSample
    % as reference to which all other slices are aligned. The range is 1
    % to the total number of slices.
    AlignSlicesReference = 1;

    %%% Pre-Filter EEG data
    % Filter the EEG data before any other processing. The filter can be
    % a low-pass, high-pass or combination of both as well as a custom
    % filter specified with its transfer function.
    % Low-Pass-Filter:
    %  - If left empty, no low-pass will be applied.
    %  - If a single frequency is specified, this applies to all channels.
    %    A frequency of 0.0 means no filter for this channel.
    %  - If a vector of frequencies is specified, every number corresponds
    %    to a channel.
    PreFilterLPFrequency = [];
    % High-Pass-Filter (same types apply). If you want a very low cut-off
    % frequency, the sharp edge of this filter will introduce ringing.
    % Consider using PreFilterGaussHPFrequency below.
    PreFilterHPFrequency = [];
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
    PreFilterHFrequencies = [];
    PreFilterHAmplitudes  = [];
    % This special pre-processing filter has a Gauss'ian transfer function,
    % which has the maximum steepness without ringing. The filter is
    % applied in addition to the above one. The same types as above apply.
    PreFilterGaussHPFrequency = [];

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
    RASequence = {
      'Cut',...
      'UpSample',...
      'AlignSlices',...
      'AlignSubSample',...
      'RemoveVolumeArt',...
      'CalcAvgArt',...
      'PCA',...
      'DownSample',...
      'Paste',...
      'LowPass',...
      'ANC' };

    %%% Interpolation
    % Interpolation factor, unset -> no interpolation
    Upsample;
    % Cutoff frequency (relative to the sampling rate) assumed by
    % interp(). Do not modify this value unless you know what you do!
    UpsampleCutoff = 0.5;
    
    %%% Sub-Sample Alignment
    % High-Pass cut-off frequency, set to 0 or [] to disable the HP
    SSAHPFrequency = 300;

    %%% Averaging of artifacts
    % Length of averaging window in number of artifacts. Will be increased
    % by 1 if not even.
    AvgWindow = 30;
    % Averaging matrix
    AvgMatrix;
    % Untyped property for UpdateAvgMatrix event listener
    AvgMatrixUpdaterData;

    %%% Optimal Basis Set (OBS) from PCA
    % Number of principal components to use in OBS. Set to 0 to skip this
    % step, set to 'auto' to determine the optimal number automatically
    % (default).
    OBSNumPCs = 'auto';
    % Channels not to perform OBS on
    OBSExcludeChannels=[];
    % High pass cutoff frequency applied before PCA
    OBSHPFrequency = 70;

    %%% Low Pass after artifact removal (but before ANC)
    % Filter cutoff frequency, unset -> no low-pass is applied. If left
    % unset and ANC is enable, it will be set to ANCDefaultLP.
    FinalLPFrequency;

    %%% Adaptive Noise Cancellation (ANC)
    % Set to true to enable ANC
    DoANC = false;

    %%% Processing of data outside of fMRI acquisition
    % Set to true to keep the data outside of the fMRI acquisition (i.e.
    %   the beginning and the end of the data) as is.
    % Set to false to use the full output of the algorithm, even outside
    %   of the fMRI acquisition area.
    DontTouchNonArtifact = true;

    %%% Execution Options
    % Profiling: print runtime information of every step
    Profiling = false;
  end

  properties(Constant=true)
    % Default cutoff frequency for the low-pass after artifact removal and
    % before the ANC
    ANCDefaultLP = 70;
    % Constants used by DoPCA
    TH_SLOPE  =  2;
    TH_CUMVAR = 80;
    TH_VAREXP =  5;
  end

  % read-only properties
  properties(GetAccess=public,SetAccess=protected)
    NumChannels;          % Number of channels
    NumSamples;           % Number of samples
    ProcessChannels;      % list of channels to be processed, is 1:NumChannels without ExcludeChannels
    SamplingFrequency;    % Sampling Frequency
    Triggers;             % An array of trigger locations, derived from EEG.event with FindTriggers()
    TriggersUp;           % Trigger locations in upsampled units relative to AcqStart
    TriggersAligned;      % positions of maximum correlation of averaged artifact and original data
    NumTriggers;          % Number of triggers in Triggers
    HalfWindow;           % ???
    PreTrig;              % Artifact start before trigger position in upsampled units
    PostTrig;             % Artifact end after trigger position in upsampled units
    ArtLength;            % Length of an artifact in upsampled units
    AcqStart;             % Start sample of fMRI acquisition (original units)
    AcqEnd;               % End   sample of fMRI acquisition (original units)
    SearchWindow;         % search window for for maximum correlation
    RunTime;              % tic-toc time of RemoveArtifact()
    RunCpuTime;           % cputime of RemoveArtifact()
    PreFilterHFreqs;      % internal cell array of filter transfer function frequency points
    PreFilterHAmpls;      % internal cell array of filter transfer function amplitude points
    PreFilterGaussHPFreqs;% internal array of filter cut-off frequencies
    %Channel;              % current channel in RemoveArtifact()
    RAEEGAll;             % RemoveArtifact inner loop: full length EEG of current channel
    RAEEGAcq;             % RemoveArtifact inner loop: partial EEG during acquisition of current channel
    RANoiseAll;           % RemoveArtifact inner loop: full length noise data of current channel
    RANoiseAcq;           % RemoveArtifact inner loop: partial noise data during acquisition of current channel
    SubSampleAlignment;   % Sub-Sample shift applied to every epoch
    OBSHPFilterWeights;   % Filter weights of high pass applied before PCA/OBS
    FinalLPFilterWeights; % Filter weights of low pass applied after PCA/OBS but before ANC
    ANCHPFrequency;       % Cut-off frequency of high pass applied before ANC
    ANCHPFilterWeights;   % Filter weights of the high pass applied before ANC
    ANCFilterOrder;       % Filter order of the ANC (not its HP!)
  end

  % private properties
  properties(Access=protected)
    FEEG;                 % Internal storage of EEGLAB data structure
    StartTime;            % start tic time of algorithm, set in Prepare()
    StartCpuTime;         % start cputime  of algorithm, set in Prepare()
    ProfilingStarts;      % stack for start tic times for profiling
  end

  % Events: executed while the algorithm is performed to update algorithm
  % data and notify the user of the progress.
  events
    EventCorrectTriggers;    % start of CorrectTriggers()
    StartPreFilter;          % start of PreFilter()
    StartRemoveArtifacts;    % start of RemoveArtifacts()
    EventRAChannelStart;     % start of a channel in RemoveArtifacts()
    EventRACut;              % notification before processing steps
    EventRAUpSample;
    EventRAAlignSlices;
    EventRAAlignSubSample;
    EventRARemoveVolumeArt;
    EventRACalcAvgArt;
    EventRAPCA;
    EventAutoResidualPCs;    % notify listener of automatically determined number of principal components
    EventRADownSample;
    EventRAPaste;
    EventRALowPass;
    EventRAANC;
    EventRAChannelDone;
    Finished;                % end of Finish()
  end

  methods(Access=public)

    % EEGFMRI  Constructor
    %
    % Checks for required Matlab toolboxes and starts the time counter
    %
    function obj=FACET()
      % check for DSP Toolbox
      if ~exist('firls','file')
        error('FACET:needSigProc','FACET requires the signal processing toolbox.');
      end
      % start time
      obj.StartTime    = tic;
      obj.StartCpuTime = cputime;
      % Put one uint64 value so that the values later pushed onto this
      % stack also have this type.
      obj.ProfilingStarts = tic;
    end

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
    function FindTriggers(obj,EventType,TriggerOffset)
      obj.Triggers = FACET.FindTriggers(obj.FEEG.event,EventType,TriggerOffset);
      % Check if triggers are sorted
      if ~issorted(obj.Triggers)
        error('FACET:unsortedTrigs','Triggers are not sorted');
      end
      % store number of triggers
      obj.NumTriggers = length(obj.Triggers);
    end

    % ANALYZEDATA  Analyze EEG dataset and your setup
    %
    % Analyze EEG dataset and print information.
    %
    % ChannelDetails
    %   Set to true to get a more detailed analysis of the channel data.
    %   For every channel its min(), max() and mean() value is shown as
    %   well as the quantization.
    %   If omitted or set to false, only a condensed list of channel labels
    %   is shown.
    %   The parameter is optional.
    %
    % This function can be used as soon obj.FEEG is assigned. It will give
    % more information after FindTriggers() was used.
    function AnalyzeData(obj,ChannelDetails)
      % set values of optional parameters
      if nargin < 2
        ChannelDetails = false;
      end
      % Complain if EEG was not set
      if isempty(obj.FEEG)
        error('FACET:needEEG','No data in EEG base structure. Did you forget to assign EEG data?');
      end

      % print information about the EEG data
      fprintf('Samples:       %d\n',obj.FEEG.pnts);
      fprintf('Sampling Rate: %d\n',obj.FEEG.srate);
      fprintf('Duration:      %4.4fs (%s)\n',obj.FEEG.pnts/obj.FEEG.srate,FACET.SecToString(obj.FEEG.pnts/obj.FEEG.srate));
      % Channels
      fprintf('Channels:      %d\n',obj.FEEG.nbchan);
      if ChannelDetails
        fprintf('Num.  Name            min         max      mean    quant.\n');
        tmin=[]; tmax=[]; tmean=0;
        for i=1:obj.FEEG.nbchan
          cmin  = min (obj.FEEG.data(i,:));   tmin  = min([tmin,cmin]);
          cmax  = max (obj.FEEG.data(i,:));   tmax  = max([tmax,cmax]);
          cmean = mean(obj.FEEG.data(i,:));   tmean = tmean+cmean;
          cstep = mode(diff(unique(obj.FEEG.data(i,:))));
          fprintf('  %2d:  %-6s  %10.2f  %10.2f  %8.2f    %6.4f\n',i,obj.FEEG.chanlocs(i).labels,cmin,cmax,cmean,cstep);
        end
        tmean=tmean/obj.FEEG.nbchan;
        fprintf('  Total:       %10.2f  %10.2f  %8.2f\n',tmin,tmax,tmean);
      else
        for i=1:obj.FEEG.nbchan
          if mod(i,10) == 1
            fprintf('  %2d-%2d:',i,min(i+9,obj.FEEG.nbchan));
          end
          fprintf(' %s',obj.FEEG.chanlocs(i).labels);
          if mod(i,10) == 0
            fprintf('\n');
          end
        end
        if mod(i,10) ~= 0
          fprintf('\n');
        end
      end
      % Events
      fprintf('Events:\n');
      for i = unique({obj.FEEG.event.type})
        n=length(FACET.FindTriggers(obj.FEEG.event,i));
        fprintf('  %-10s %5dx\n',['''' i{1} ''''],n);
      end
      [amin,amax] = obj.FindAcquisition();
      adur=amax-amin+1;
      fprintf('Acquisition\n');
      fprintf('  approx. begin:    %7d  (%7.2fs)\n',amin,amin/obj.FEEG.srate);
      fprintf('  approx. end:      %7d  (%7.2fs)\n',amax,amax/obj.FEEG.srate);
      fprintf('  approx. duration: %7d  (%7.2fs)\n',adur,adur/obj.FEEG.srate);
      abef = amin-1;
      aaft = obj.FEEG.pnts - (amax+1);
      atot = abef+aaft;
      fprintf('Non-Acquisition\n');
      fprintf('  approx. before:   %7d  (%7.2fs)\n',abef,abef/obj.FEEG.srate);
      fprintf('  approx. after:    %7d  (%7.2fs)\n',aaft,aaft/obj.FEEG.srate);
      fprintf('  approx. total:    %7d  (%7.2fs)\n',atot,atot/obj.FEEG.srate);

      % Complain if FindTriggers was not yet called
      if isempty(obj.Triggers)
        fprintf('No triggers setup. Use FindTriggers() and re-run this function\n  to get more information.\n');
        return;
      end

      % Analyze triggers
      TrigsDiff = diff(obj.Triggers);   % [ T2-T1  T3-T2  T4-T3 ... ]
      % show histogram of trigger distances
      [TrigsDiffHist,TrigsDiffVal] = hist(TrigsDiff,min(TrigsDiff):max(TrigsDiff));
      fprintf('Trigger Distances Histogram\n');
      for i=1:length(TrigsDiffHist)
        if TrigsDiffHist(i) ~= 0
          fprintf('  %4d (%4.2fms): %5dx %s\n',TrigsDiffVal(i),TrigsDiffVal(i)/obj.FEEG.srate*1000,TrigsDiffHist(i),char('#'*ones(1,round(60*TrigsDiffHist(i)/length(TrigsDiff)))));
        end
      end
      % Check if there are big holes
      MeanTrigsDiff = mean(TrigsDiff);
      if TrigsDiffVal(end) > 1.8 * MeanTrigsDiff
        fprintf('WARNING: Maximum triggers distance is more than 1.8x the mean distance. Some\n  triggers might be missing. Try FindMissingTriggers().\n');
      end
      % Check if we have enough triggers
      if round(adur/MeanTrigsDiff) > obj.NumTriggers
        fprintf('WARNING: Comparing mean triggers difference with total acquisition duration\n  suggests that triggers are missing (have: %d, approx. required: %.2f)\n  Try FindMissingTriggers() and AddTriggers.\n',obj.NumTriggers,adur/MeanTrigsDiff);
      end
      % determine whether this are volume or slice triggers
      MeanTrigsDur = MeanTrigsDiff/obj.FEEG.srate;
      if MeanTrigsDur > 1.0
        fprintf('Mean trigger distances %.2fs are larger than 1.0s, assuming VOLUME triggers.\n',MeanTrigsDur);
        SliceTrigs = false;
      else
        fprintf('Mean trigger distances %.2fms are less than 1.0s, assuming SLICE triggers.\n',MeanTrigsDur*1000);
        SliceTrigs = true;
      end
      % determine if we have volume gaps
      if SliceTrigs
        % check if histogram has two peaks
        % Due to asynchronous sampling the distances might vary a bit. We
        % accept one mean value, plus and minus one (gives a range of 2),
        % plus one more to be a bit more robust.
        if TrigsDiffVal(end) - TrigsDiffVal(1) > 3
          % wide histogram, first hint
          % determine center of histogram
          HistEndSlice = floor(mean([1, length(TrigsDiffVal)]));
          HistBeginVol = ceil (mean([1, length(TrigsDiffVal)]));
          HistBeginVol = max(HistEndSlice+1,HistBeginVol);  % ensure different values
          % calculate separate volume and slice distances
          SliceDist = sum(TrigsDiffHist(1:HistEndSlice)   .* TrigsDiffVal(1:HistEndSlice))   / sum(TrigsDiffHist(1:HistEndSlice));
          VolDist   = sum(TrigsDiffHist(HistBeginVol:end) .* TrigsDiffVal(HistBeginVol:end)) / sum(TrigsDiffHist(HistBeginVol:end));
          % calculate number of slices and volumes
          SliceDistCount = sum(TrigsDiffHist(1:HistEndSlice));
          VolDistCount   = sum(TrigsDiffHist(HistBeginVol:end));
          VolCount   = VolDistCount   + 1;
          SliceCount = SliceDistCount + VolCount;
          fprintf('Found %d smaller (slice) distances of %2.2fms and %d larger (volume)\n  distances of %2.2fms, with a volume gap of %2.2fms.\n',SliceDistCount,SliceDist/obj.FEEG.srate*1000,VolDistCount,VolDist/obj.FEEG.srate*1000,(VolDist-SliceDist)/obj.FEEG.srate*1000);
          if mod(SliceCount,VolCount) == 0
            fprintf('This most probably shows an fMRI acquisition of %d volumes with %d slices\n  each, %d in total.\n',VolCount,SliceCount/VolCount,SliceCount);
          else
            fprintf('WARNING: Total slice count %d is not an integer multiple of the estimated\n  volume count %d.\n',SliceCount,VolCount);
          end
        else
          fprintf('Small variation of trigger distances. No volume gaps assumed.\n');
        end
      else
        % Volume Triggers
        % Take one trigger interval somewhere in the middle
        VolumeIdx = round(length(obj.Triggers)/2);
        Volume = sum(obj.FEEG.data(:,obj.Triggers(VolumeIdx):obj.Triggers(VolumeIdx+1)),1);   % sum along channel index
        % calculate auto-correlation, but only over 1/10th, we assume at least 10 slices per volume
        corr = xcorr(Volume,ceil(length(Volume)/10));
        % shift=0 is at ceil(length(corr)/2), since it is symmetric we continue with one-sided data
        corr = corr(ceil(length(corr)/2):end);
        self = corr(1);   % store maximum value, i.e. when correlated with itself without shift
        % set all values below 80% of the maximum to 0
        corr(corr<0.8*self)=0;
        % find peaks
        [peaks,idx]=findpeaks(corr);
        % corr(1) is _not_ in this set, because it has no rising/falling part but only a falling one
        % calculate distance between peaks (including self-correlation)
        dist=diff([1 idx]);
        SliceDistAvg = mean(dist);
        SliceDistStd = std(dist);
        SlicePerVolume = MeanTrigsDiff / SliceDistAvg;
        fprintf('Found slice periode of %1.2f samples (std.dev. %1.2f).\n  Slice time = %1.2fms, slice frequeny = %1.2fHz\n  %1.2f slices per volume\n',SliceDistAvg,SliceDistStd,SliceDistAvg/obj.FEEG.srate*1000,obj.FEEG.srate/SliceDistAvg,SlicePerVolume);
        % warn if the standard deviation is above 2% of the mean
        if SliceDistStd > 0.02 * SliceDistAvg
          % large variation -> probably not what we wanted or some maxima missed
          fprintf('WARNING: High std.dev indicates unreliable results. Distances between\n  maxima are %s\n',mat2str(dist));
        end
      end
    end

    % FINDMISSINGTRIGGERS  Find missing triggers
    %
    % Use this methods if some triggers during the acquisition are missing.
    %
    % Important: This function can only find triggers which are between the
    % first and the last triggers as denoted by EEG.event. It doesn't add
    % triggers before the first and after the last. Use AddTriggers() in
    % this case.
    %
    % Volumes
    %   Total number of fMRI volumes withing EEG.event.
    % Slices
    %   fMRI slices per volume. Set to 1 if FindTriggers was used for
    %   volume triggers.
    function FindMissingTriggers(obj,Volumes,Slices)
      % Return if we have the correct number of triggers
      if length(obj.Triggers) == Volumes*Slices
        % nothing to do
        return;
      end
      notify(obj,'EventCorrectTriggers');
      % Reconstruct missing triggers
      obj.Triggers = obj.CompleteTriggers(obj.Triggers,Volumes,Slices);
      % store new number of triggers
      obj.NumTriggers = length(obj.Triggers);
    end

    % ADDTRIGGERS  Add triggers outside of defined trigger range
    %
    % Use this method if some triggers before the first or after the last
    % are missing.
    %
    % Where
    %   Sample indices into EEG.data to add to the trigger array.
    function AddTriggers(obj,Where)
      if (min(Where) < 1) || (max(Where) > obj.FEEG.pnts)
        error('FACET:AddTriggersOutOfRange','Triggers (%d - %d) out of range 1-%d',min(Where),max(Where),obj.FEEG.pnts);
      end
      common = intersect(obj.Triggers,Where);
      if ~isempty(common)
        error('FACET:AddTriggersDuplicate','Trigger(s) %s are duplicate',mat2str(common));
      end
      % add new trigger locations
      obj.Triggers = sort([obj.Triggers Where]);
      % store number of triggers
      obj.NumTriggers = length(obj.Triggers);
    end

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
    function GenerateSliceTriggers(obj,Slices,Duration,RelPos)
      SliceTrigs = round(((0:(Slices-1)) - RelPos) * Duration);
      NewTrigs = zeros(1,Slices*obj.NumTriggers);
      for i=1:obj.NumTriggers
        NewTrigs((1:Slices)+(i-1)*Slices) = obj.Triggers(i) + SliceTrigs;
      end
      obj.Triggers=NewTrigs;
      % store number of triggers
      obj.NumTriggers = length(obj.Triggers);
      % change setting
      obj.SliceTrigger = true;
    end

    % CHECKDATA  Check EEG dataset and your setup
    %
    % Check EEG dataset and your setup for any notable or problematic
    % conditions.
    %
    function CheckData(obj)
      % Complain if EEG was not set
      if isempty(obj.FEEG)
        error('FACET:needEEG','No data in EEG base structure. Did you forget to assign EEG data?');
      end
      % Complain if FindTriggers was not yet called
      if isempty(obj.Triggers)
        error('FACET:needTrigs','No triggers setup. Did you forget to use FindTriggers()?');
      end
      % TODO: check more, especially the setup
    end

    % Prepare: start of the algorithm
    function Prepare(obj)
      obj.DeriveVars;
    end

    function PreFilter(obj)
      if isempty(obj.PreFilterHFreqs) && isempty(obj.PreFilterGaussHPFreqs)
        return
      end
      obj.ProfileStart();
      notify(obj,'StartPreFilter');
      % calculate borders between artifact and non-artifact periods
      ArtStart = obj.AcqStart+round((obj.TriggersUp(  1)-obj.PreTrig )/obj.Upsample);
      ArtEnd   = obj.AcqStart+round((obj.TriggersUp(end)+obj.PostTrig)/obj.Upsample);
      End      = size(obj.FEEG.data,2);
      % Visualize
      % plot(obj.FEEG.data(1,:));
      % hold on
      % plot(obj.FEEG.data(2,:),'r');
      % plot(obj.FEEG.data(3,:),'g');
      % plot(obj.FEEG.data(4,:),'c');
      % plot(obj.FEEG.data(5,:),'m');
      % stem(ArtStart,1e4,'k');
      % stem(ArtEnd,1e4,'k');      
      for Channel = obj.ProcessChannels
        % before acquisition
        obj.PreFilterRun      (Channel,1,           ArtStart);
        % during acquisition
        obj.PreFilterRunPadded(Channel,(ArtStart+1),ArtEnd);
        % after acquisition
        obj.PreFilterRun      (Channel,(ArtEnd+1),  End);
      end
      % profiling information
      obj.ProfileStop();
    end

  end

  methods(Access=private)

    function PreFilterRun(obj,Channel,From,To)
      data = obj.FEEG.data(Channel,From:To);
      if ~isempty(obj.PreFilterHFreqs) && ~isempty(obj.PreFilterHFreqs(Channel))
        f = cell2mat(obj.PreFilterHFreqs(Channel));
        a = cell2mat(obj.PreFilterHAmpls(Channel));
        data = FACET.fftfilt(data,f,a);
        % TODO: undo shift
      end
      if ~isempty(obj.PreFilterGaussHPFreqs)
        HPf = obj.PreFilterGaussHPFreqs(Channel);
        data = FACET.fftgausshp(data,HPf,obj.FEEG.srate);
      end
      obj.FEEG.data(Channel,From:To) = data;
    end

    function PreFilterRunPadded(obj,Channel,From,To)
      data = obj.FEEG.data(Channel,From:To);
      % prepend data with enough copies of the first artifact to let the filter taps settle
      ArtLen = obj.Triggers(2)-obj.Triggers(1);
      ArtS = data(1:ArtLen);
      Num = ceil(1*obj.SamplingFrequency/ArtLen)+1;   % prequel should be longer than the filter 1/f_c
      % append data for the reverse filter
      ArtLen = obj.Triggers(end)-obj.Triggers(end-1);
      ArtE = data(end-ArtLen:end);
      % add data
      data = [repmat(ArtS,1,Num) data repmat(ArtE,1,Num)];
      % filter (don't use one common function for this filter stuff here,
      % because this would require a function call with parameters, for
      % which the potentially large "data" array would have to be
      % duplicated in memory)
      if ~isempty(obj.PreFilterHFreqs) && ~isempty(obj.PreFilterHFreqs(Channel))
        f = cell2mat(obj.PreFilterHFreqs(Channel));
        a = cell2mat(obj.PreFilterHAmpls(Channel));
        data = FACET.fftfilt(data,f,a);
        % TODO: undo shift
      end
      if ~isempty(obj.PreFilterGaussHPFreqs)
        HPf = obj.PreFilterGaussHPFreqs(Channel);
        data = FACET.fftgausshp(data,HPf,obj.FEEG.srate);
      end
      % cut out interesting part
      data = data((length(ArtS)*Num+1):(end-length(ArtE)*Num));
      % store
      obj.FEEG.data(Channel,From:To) = data;
    end

  end

  methods(Access=public)

    % Perform the artifact removal
    function RemoveArtifacts(obj)
      notify(obj,'StartRemoveArtifacts');

      % iterate over all channels
      for Channel = obj.ProcessChannels

        % profiling start
        obj.ProfileStart();
        % notify
        notify(obj,'EventRAChannelStart',FACET.EventDataOneParam(Channel));

        % prepare data
        % cast EEG to double, which previously was implicitely done by
        % interp()
        obj.RAEEGAll   = double(obj.FEEG.data(Channel,:));
        obj.RANoiseAll = zeros(size(obj.RAEEGAll));

        % execute RASequence
        for i = 1:length(obj.RASequence)
          % profiling
          obj.ProfileStart();
          % step information
          Step = obj.RASequence{i};
          % function handle?
          if strcmp(class(Step),'function_handle')
            % execute function handle
            Step(obj,i,Channel);
            % done profiling
            obj.ProfileStop(func2str(Step));
            continue;
          end
          % send event to listeneners of coming processing step
          notify(obj,strcat('EventRA',Step),FACET.EventDataOneParam(Channel));
          % perform processing step
          switch Step
            case 'Cut',              obj.RACut();
            case 'UpSample',         obj.RAUpSample();
            case 'AlignSlices',      obj.RAAlignSlices(Channel);
            case 'AlignSubSample',   obj.RAAlignSubSample();
            case 'RemoveVolumeArt',  obj.RARemoveVolumeArtifact();
            case 'CalcAvgArt',       obj.RACalcAvgArt(Channel);
            case 'PCA',              obj.RAPCA(Channel);
            case 'DownSample',       obj.RADownSample();
            case 'Paste',            obj.RAPaste();
            case 'LowPass',          obj.RALowPass();
            case 'ANC',              obj.RAANC();
            otherwise,
              error('FACET:RemoveArtifact:InvalidStep','Invalid artifact removal step "%s"',Step);
          end
          % done profiling
          obj.ProfileStop(Step);
        end

        % store data
        if obj.DontTouchNonArtifact
          % keep data outside of acquisition untouched
          obj.FEEG.data(Channel,obj.AcqStart:obj.AcqEnd)=obj.RAEEGAll(obj.AcqStart:obj.AcqEnd);
        else
          % use full data filtered by the algorithm above
          obj.FEEG.data(Channel,:)=obj.RAEEGAll;
        end

        % notify
        notify(obj,'EventRAChannelDone');
        % done profiling
        obj.ProfileStop(['Channel ' num2str(Channel)]);

      end   % for Channel = ProcessChannels
    end

    % Cleanup after algorithm execution
    function Finish(obj)
      obj.RunTime    = toc(obj.StartTime);
      obj.RunCpuTime = cputime-obj.StartCpuTime;
      notify(obj,'Finished');
    end

  end

  methods % setters
    % web([docroot '/techdoc/matlab_oop/brgsek9-1.html'])

    % Matlab's setter methods are not planned to be used as I'd like it
    % here. They seem only intended for validating an assigned value, but
    % nothing else.
    %  - setter name must refer to a valid property name, so you can't
    %    create "virtual" properties, except with the 'Dependent' flag
    %  - setters should not access other properties as shown by the linting
    %    warnings, so you can't use them to derive values from them, but
    %    the documentation proposes exactly this usage
    %  - the referred property must either be set/get public or set/get
    %    protected/private, but not mixed (e.g. public get and protected
    %    set), otherwise a runtime error issued.
    function obj = set.EEG(obj,EEG)
      % Check consistency of EEG data structure
      if EEG.nbchan ~= size(EEG.data,1)
        error('FACET:EEGnbchan','EEG.nbchan (%d) is not equal to the number of rows in EEG.data (%d)',EEG.nbchan,size(EEG.data,1));
      end
      if EEG.pnts ~= size(EEG.data,2)
        error('FACET:EEGpnts','EEG.pnts (%d) is not equal to the number of columns in EEG.data (%d)',EEG.pnts,size(EEG.data,2));
      end
      if size(EEG.chanlocs,2) ~= EEG.nbchan
        error('FACET:EEGchanlocs','EEG.chanlocs has different number of entries (%d) than channels (%d)',size(EEG.chanlocs,2),EEG.nbchan);
      end
      if abs((EEG.xmax-EEG.xmin) - (EEG.pnts-1)/EEG.srate) > 1e-9
        error('FACET:EEGxmax','EEG.xmax-EEG.xmin (%4.4f) is not equal to the number calculated from EEG.pnts/EEG.srate (%4.4f)',EEG.xmax-EEG.xmin,EEG.pnts/EEG.srate);
      end
      % Set property
      obj.FEEG = EEG;
      % Get values from EEG
      [obj.NumChannels obj.NumSamples] = size(obj.FEEG.data);
      obj.SamplingFrequency = obj.FEEG.srate;
    end
    function EEG = get.EEG(obj)
      EEG = obj.FEEG;
    end

    function obj = set.ExcludeChannels(obj,ExcludeChannels)
      % Set property
      obj.ExcludeChannels = ExcludeChannels;
      % Define list of channels to process
      obj.ProcessChannels = setdiff(1:obj.NumChannels,obj.ExcludeChannels);
    end

    function obj = set.OBSExcludeChannels(obj,OBSExcludeChannels)
      % Set property
      obj.OBSExcludeChannels = sort(OBSExcludeChannels);
      % Check that OBSExcludeChannels 
      if isempty(obj.OBSExcludeChannels)
        return
      end
      if obj.OBSExcludeChannels(end)>obj.NumChannels || obj.OBSExcludeChannels(1)<1
          error('FACET:invalidOBSExcludeChannel','Channel to exclude from OBS out of range 1..%d',obj.NumChannels);
      end
    end
    
    function obj = set.OBSNumPCs(obj,OBSNumPCs)
      % Set property
      obj.OBSNumPCs = OBSNumPCs;
      % Check that OBSNumPCs has a valid value
      if ischar(obj.OBSNumPCs)
        if ~strcmpi(obj.OBSNumPCs,'auto')
          error('FACET:invalidOBSNumPCs','Invalid value of OBSNumPCs ''%s'', allowed are numbers 0..n and ''auto''\n',obj.OBSNumPCs);
        end
      end
    end

  end

  methods(Access=protected)

    function CalcArtLength(obj,Triggers)
      d = diff(Triggers);   % trigger distances
      if obj.VolumeGaps
        m = mean([min(d), max(d)]);            % middle distance
        ds = d(d<m);                           % trigger distances belonging to slice triggers
        dv = d(d>m);                           % trigger distances belonging to volume triggers

        % total length of an artifact
        obj.ArtLength = max(ds); % use max to avoid gaps between slices
      else
        % total length of an artifact
        obj.ArtLength = max(d);
      end
    end

    function CalcArtPos(obj,PreTrig)
      % Artifact start before trigger
      obj.PreTrig     = PreTrig;
      % Artifact end after trigger
      obj.PostTrig    = obj.ArtLength - obj.PreTrig - 1;
    end

    % Calculate internal variables which depend on the public properties
    function DeriveVars(obj)
      % Correct AvgWindow with actual number of triggers
      obj.CorrectAvgWindow();

      % Calculate HalfWindow
      if obj.SliceTrigger
        obj.HalfWindow=obj.AvgWindow;
      else
        % Why? TODO: search in paper
        obj.HalfWindow=obj.AvgWindow/2;
      end
      
      % Check whether the data has volume-gaps
      if isempty(obj.VolumeGaps)
        % Due to asynchronous sampling the distances might vary a bit. We
        % accept one mean value, plus and minus one (gives a range of 2),
        % plus one more to be a bit more robust.
        if range(diff(obj.Triggers)) > 3
          obj.VolumeGaps = true;
        else
          obj.VolumeGaps = false;
        end
      end

      % calculate ArtLength
      obj.CalcArtLength(obj.Triggers*obj.Upsample);
      % calculate PreTrig and PostTrig
      obj.CalcArtPos(round(obj.ArtLength*obj.RelTrigPos));

      % start and end samples of fMRI acquisition
      obj.AcqStart = max(1,                    obj.Triggers(1)   - ceil(1.25*obj.ArtLength/obj.Upsample));
      obj.AcqEnd   = min(length(obj.FEEG.data),obj.Triggers(end) + ceil(2.25*obj.ArtLength/obj.Upsample));

      % trigger locations for up-sampled data, will be refined by RAAlignSlices
      obj.TriggersUp=(obj.Triggers-obj.AcqStart+1)*obj.Upsample;

      % search window for for maximum correlation
      obj.SearchWindow=round(3*obj.Upsample);

      %%% Calculating PCA-HP filter weights for template formation %%%%%%%%
      nyq=0.5*obj.SamplingFrequency;
      trans=0.15;

      filtorder=round(1.2*obj.SamplingFrequency*obj.Upsample/(obj.OBSHPFrequency-10));
      if rem(filtorder,2)~=0      % ensure filtorder is odd
          filtorder=filtorder+1;
      end

      % get filter coefficients for transfer function which is 0 from 0Hz
      % to PCAHPFrequency-10 and 1 from PCAHPFrequency+10 to Nyquist
      f=[0 (obj.OBSHPFrequency-10)/(nyq*obj.Upsample)...
           (obj.OBSHPFrequency+10)/(nyq*obj.Upsample) 1]; 
      a=[0 0 1 1];
      obj.OBSHPFilterWeights=firls(filtorder,f,a);

      %%% Calculating pre filter weights %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      if ~isempty(obj.PreFilterLPFrequency) || ~isempty(obj.PreFilterHPFrequency) || ~isempty(obj.PreFilterHFrequencies)
        % make PreFilterLPFrequency a vector
        PFLP = obj.PreFilterLPFrequency;   % use a local variable as shortcut
        if isempty(PFLP)
          % empty -> no LPs -> make a vector with all 0s
          PFLP = zeros(1,obj.NumChannels);
        elseif size(PFLP) == [1 1]
          % single number -> make a vector from it
          PFLP = PFLP * ones(1,obj.NumChannels);
        elseif size(PFLP) == [1 obj.NumChannels]
          % vector of correct size -> nothing to do
        else
          error('FACET:PreFilterLPFrequency','Invalid data type for PreFilterLPFrequency');
        end

        % make PreFilterHPFrequency a vector
        PFHP = obj.PreFilterHPFrequency;   % use a local variable as shortcut
        if isempty(PFHP)
          % empty -> no HPs -> make a vector with all 0s
          PFHP = zeros(1,obj.NumChannels);
        elseif size(PFHP) == [1 1]
          % single number -> make a vector from it
          PFHP = PFHP * ones(1,obj.NumChannels);
        elseif size(PFHP) == [1 obj.NumChannels]
          % vector of correct size -> nothing to do
        else
          error('FACET:PreFilterHPFrequency','Invalid data type for PreFilterHPFrequency');
        end

        % make PreFilterH{Freqs,Ampls} cell arrays
        obj.PreFilterHFreqs = cell(1,obj.NumChannels);
        obj.PreFilterHAmpls = cell(1,obj.NumChannels);
        PFF = obj.PreFilterHFrequencies;   % use a local variable as shortcut
        PFA = obj.PreFilterHAmplitudes;
        if isempty(PFF)
          % empty -> generate from the HP and LP specification
          for c = 1:obj.NumChannels    % we generate filters for all channels, even when we do not use them w.r.t. ExcludeChannels
            f = []; a = [];
            if PFLP(c) > 0 && PFHP(c) > 0
              % LP and HP given -> band pass
              f = [ 0 PFHP(c)*0.99 PFHP(c)*1.01 PFLP(c)*0.99 PFLP(c)*1.01 nyq] / nyq;
              a = [ 0            0            1            1            0   0];
            elseif PFLP(c) > 0
              % LP but no HP given -> low pass
              f = [ 0 PFLP(c)*0.95 PFLP(c)*1.05 nyq] / nyq;
              a = [ 0            0            1   1];
            elseif PFHP(c) > 0
              % HP but no LP given -> high pass
              f = [ 0 PFHP(c)*0.95 PFHP(c)*1.05 nyq] / nyq;
              a = [ 0            0            1   1];
            end
            if ~isempty(f)
              obj.PreFilterHFreqs(c) = {f};
              obj.PreFilterHAmpls(c) = {a};
            end
          end
        elseif isnumeric(PFF) && size(PFF,1) == 1
          % single-row vector -> fill the cell array with vectors
          for c = 1:obj.NumChannels
            obj.PreFilterHFreqs(c) = {PFF};
            obj.PreFilterHAmpls(c) = {PFA};
          end
        elseif iscell(PFW) && size(PFW,1) == obj.NumChannels
          % cell array of correct size -> copy to internal variable
          obj.PreFilterHFreqs(c) = {PFF};
          obj.PreFilterHAmpls(c) = {PFA};
        else
          error('FACET:PreFilterH','Invalid data type of PreFilterH{Frequencies,Amplitudes}');
        end
      end
      % Gauss HP
      if ~isempty(obj.PreFilterGaussHPFrequency)
        % make PreFilterGaussHPFrequency a vector
        PFGHP = obj.PreFilterGaussHPFrequency;   % use a local variable as shortcut
        if isempty(PFGHP)
          % empty -> no HPs -> keep it as is
        elseif size(PFGHP) == [1 1]
          % single number -> make a vector from it
          PFGHP = PFGHP * ones(1,obj.NumChannels);
        elseif size(PFGHP) == [1 obj.NumChannels]
          % vector of correct size -> keep it as is
        else
          error('FACET:PreFilterGaussHPFrequency','Invalid data type for PreFilterGaussHPFrequency');
        end
        obj.PreFilterGaussHPFreqs = PFGHP;
      end

      %%% Calculating LP filter weights %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      if obj.FinalLPFrequency>0
        minorder=15;
        minfac=3;

        if (1+trans)*obj.FinalLPFrequency/nyq > 1
            error('FACET:LPFcutoff','Final low pass filter cutoff frequency too close to Nyquist frequency.');
        end

        filtorder=max(minorder,round(minfac*fix(obj.SamplingFrequency/obj.FinalLPFrequency)));
        if rem(filtorder,2)~=0       % ensure filtorder is even
            filtorder=filtorder+1;
        end

        f=[0 obj.FinalLPFrequency/nyq obj.FinalLPFrequency*(1+trans)/nyq 1];
        a=[1 1 0 0];
        obj.FinalLPFilterWeights=firls(filtorder,f,a);
      end

      %%% Calculating ANC-HP filter weights %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      if obj.SliceTrigger
        % find number of triggers within the first second, i.e. estimate
        % the frequency of triggers
        Tr=1;
        while Tr<=obj.NumTriggers
          Trtime=obj.Triggers(Tr+1)-obj.Triggers(1);
          if Trtime>=obj.SamplingFrequency
            break
          end
          Tr=Tr+1;
        end
        % ANC HP cut-off frequency is 25% lower than the estimated trigger
        % frequency.
        obj.ANCHPFrequency=0.75*Tr;
      else
        obj.ANCHPFrequency=2;
      end
      filtorder=round(1.2*obj.SamplingFrequency/(obj.ANCHPFrequency*(1-trans)));
      if rem(filtorder,2)~=0
        filtorder=filtorder+1;
      end
      f=[0 obj.ANCHPFrequency*(1-trans)/nyq obj.ANCHPFrequency/nyq 1];
      a=[0 0 1 1];
      obj.ANCHPFilterWeights=firls(filtorder,f,a);

      obj.ANCFilterOrder=double(ceil(obj.ArtLength / obj.Upsample));
    end

    function CorrectAvgWindow(obj)
      return;
      % TODO: check what this was good for at Niazy, then make it optional
      % Ensure AvgWindow (number of artifacts to average) is even
      if rem(obj.AvgWindow,2) ~= 0
        obj.AvgWindow = obj.AvgWindow + 1;
      end

      % Reduce AvgWindow if too large
      if obj.SliceTrigger
        if obj.AvgWindow > floor((obj.NumTriggers-3)/2)
          obj.AvgWindow = floor((obj.NumTriggers-3)/2);
          % ensure AvgWindow is even
          if rem(obj.AvgWindow,2) ~= 0
            obj.AvgWindow = obj.AvgWindow-1;
          end
          warning('FACET:maxAvgWin','For %d slice triggers, the maximum averaging\nwindow length allowed is %d. Window length set to %d.\n',obj.NumTriggers,obj.AvgWindow,obj.AvgWindow);
        end
      else   % Volume/Section triggers
        if obj.AvgWindow > obj.NumTriggers-2
          obj.AvgWindow = obj.NumTriggers-2;
          % ensure AvgWindow is even
          if rem(obj.AvgWindow,2) ~= 0
            obj.AvgWindow = obj.AvgWindow-1;
          end
          warning('FACET:maxAvgWin','For %d volume triggers, the maximum averaging\nwindow length allowed is %d. Window length set to %d.\n',obj.NumTriggers,obj.AvgWindow,obj.AvgWindow);
        end
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % RemoveArtifact sub-functions
    %
    % Principle: all these functions operate on the object properties
    % RAEEG* and RANoise*, where the first is the (cleaned) EEG data, the
    % second one the extimated noise.
    %
    % For both variables two forms exist: RA*All and RA*Acq. The first
    % contains the whole data, i.e. length(RA*All) = length(EEG.data(1,:)),
    % while the second with postfix 'Acq' only holds part of this during
    % the fMRI acquisition periode.
    %
    % Important: some functions operate on RA*All, some others on RA*Acq,
    % so pay attention on the order. "Conversion" is done using RACut()
    % and RAPaste().

    % Cut acquisition periode from full-length EEG and noise data
    %
    % in:  RAEEGAll, RANoiseAll
    % out: RAEEGAcq, RANoiseAcq
    function RACut(obj)
      obj.RAEEGAcq   = obj.RAEEGAll  (obj.AcqStart:obj.AcqEnd);
      obj.RANoiseAcq = obj.RANoiseAll(obj.AcqStart:obj.AcqEnd);
    end

    % Paste acquisition periode (back) to full-length EEG and noise data
    %
    % in:  RAEEGAcq, RANoiseAcq
    % out: RAEEGAll, RANoiseAll
    function RAPaste(obj)
      obj.RAEEGAll  (obj.AcqStart:obj.AcqEnd)=obj.RAEEGAcq;
      obj.RANoiseAll(obj.AcqStart:obj.AcqEnd)=obj.RANoiseAcq;
    end

    % Up-sampling
    %
    % in:  RAEEGAcq
    % out: RAEEGAcq
    function RAUpSample(obj)
      if obj.Upsample > 1
        % If UpsampleCutoff > 0.5, the filled samples show arcs towards
        % 0.0. To be equivalent to Niazy and to avoid too large arcs just
        % because of a DC bias, we do the interpolation with a zero-mean
        % DC free signal and add it afterwards.
        % Note that if RAEEGAcq is of type single, m will be too and the
        % term +m after interp() converts its result (which is always
        % double) back to single. So be sure to have RAEEGAcq cast to
        % double early enough (or cast m, but better cast the data
        % explicitely).
        m = mean(obj.RAEEGAcq);
        obj.RAEEGAcq = interp(obj.RAEEGAcq-m,obj.Upsample,4,obj.UpsampleCutoff)+m;
        if (range(obj.RANoiseAcq) == 0) && (obj.RANoiseAcq(1) == 0)
          % don't do expensive interpolation on all-zeros data
          obj.RANoiseAcq = zeros(size(obj.RAEEGAcq));
        else
          obj.RANoiseAcq = interp(obj.RANoiseAcq,obj.Upsample,4,obj.UpsampleCutoff);
        end
      end
    end

    % Align all epochs with sample granularity to maximize correlation
    % with first epoch
    %
    % in:  RAEEGAcq, TriggersUp
    % out: TriggersUp, ArtLength, PreTrig, PostTrig
    function RAAlignSlices(obj,Channel)
      if Channel ~= 1
        return   % don't repeat our work for later channels
      end
      % copy template from first channel and first artifact
      OneArtifact=obj.RAEEGAcq(obj.TriggersUp(obj.AlignSlicesReference)-obj.PreTrig:obj.TriggersUp(obj.AlignSlicesReference)+obj.PostTrig);
      % for every following artifact:
      for s=setdiff(1:obj.NumTriggers,obj.AlignSlicesReference)
        try
          % adjust trigger location
          shift = FACET.FindMaxCrossCorr(obj.RAEEGAcq,OneArtifact,obj.TriggersUp(s),obj.PreTrig,obj.SearchWindow);
          obj.TriggersUp(s) = obj.TriggersUp(s) + shift;
        catch e
          warning('FACET:RAAlignSlices','Problem during slice alignment at trigger %d: %s:%s',s,e.identifier,e.message);
        end
      end

      % calculate ArtLength with refined TriggersUp
      obj.CalcArtLength(obj.TriggersUp);

      if obj.AutoPreTrig
        % determine PreTrig, i.e. the acquisition onset
        Window = max(obj.PreTrig,2*obj.Upsample)*3;   % search window start before TriggersUp(1)
        % use minimum value to avoid problems with DiffSum if Window=0
        First  = obj.RAEEGAcq(obj.TriggersUp(1)-Window:obj.TriggersUp(1)+obj.ArtLength);  % don't use TriggersUp(2) as end here, because the distance between the 1-2 and 2-3 might be different
        Second = obj.RAEEGAcq(obj.TriggersUp(2)-Window:obj.TriggersUp(2)+obj.ArtLength);
        DiffSum = zeros(1,Window);
        for i=1:Window
          Second(i) = First(1);   % successively set samples of Second to zero
          % TODO: shouldn't we set it to First(1) instead of 0.0 in the hope that this is more or less the clean EEG value with some silly offset?
          DiffSum(i) = sum(abs(First-Second).^2);  % difference is the measure
        end
        [Min,Pos] = min(DiffSum);
        NewPreTrig = Window - Pos + 1;
      else
        % CalcArtPos below can't be skipped because some other values have
        % changed too. So simply give it the old PreTrig value. :-)
        NewPreTrig = obj.PreTrig;
      end

      % calculate PreTrig and PostTrig
      obj.CalcArtPos(NewPreTrig);
    end

    % Align all epochs with sub-sample granularity to maximize correlation
    % with first epoch
    %
    % in:  RAEEGAcq
    % out: RAEEGAcq
    function RAAlignSubSample(obj)
      obj.AlignSubSample();
    end

    function RARemoveVolumeArtifact(obj)
      d = diff(obj.TriggersUp);   % trigger distances
      m = mean([min(d), max(d)]); % middle distance
      vt = find(d>m);             % trigger distances belonging to volume triggers
      % vt is a vector with indices into obj.TriggersUp which selects the
      % slice period _before_ a volume artifact occurs

      SelIdx = -obj.PreTrig:obj.PostTrig;

      % prepare weight function for artifact
      x=(1:obj.ArtLength)/obj.ArtLength;
      Pos   = 0.8;  % position of 0.5 relative within slice periode, 0.0 = start, 1.0 = end
      Slope = 20;   % slope of weighting function
      Weight = 1./(1+exp(-Slope * (x-Pos)));   % logistic function

      % number of slices to average for template
      TmplNumAvg = 5;

      for Slice = 1:length(vt)
        TrigPre = vt(Slice);
        DataPre = obj.RAEEGAcq(SelIdx + obj.TriggersUp(TrigPre));
        % use slices before this slice as template
        TmplPre = zeros(size(SelIdx));
        for i = 1:TmplNumAvg
          TmplPre = TmplPre + obj.RAEEGAcq(SelIdx + obj.TriggersUp(TrigPre-i));
        end
        TmplPre = TmplPre / TmplNumAvg;

        TrigPost = vt(Slice)+1;
        DataPost = obj.RAEEGAcq(SelIdx + obj.TriggersUp(TrigPost));
        % use slices after this slice as template
        TmplPost = zeros(size(SelIdx));
        for i = 1:TmplNumAvg
          TmplPost = TmplPost + obj.RAEEGAcq(SelIdx + obj.TriggersUp(TrigPost+i));
        end
        TmplPost = TmplPost / TmplNumAvg;

        VolArtPre  = DataPre  - TmplPre;
        VolArtPost = DataPost - TmplPost;

        VolArtPre  = VolArtPre .* Weight;
        VolArtPost = VolArtPost .* Weight(obj.ArtLength:-1:1);

        DataPre  = DataPre  - VolArtPre;
        DataPost = DataPost - VolArtPost;

        obj.RAEEGAcq(SelIdx + obj.TriggersUp(TrigPre))  = DataPre;
        obj.RAEEGAcq(SelIdx + obj.TriggersUp(TrigPost)) = DataPost;

        GapIdx = (obj.TriggersUp(TrigPre)+obj.PostTrig+1):(obj.TriggersUp(TrigPost)-obj.PreTrig-1);
        GapLen = length(GapIdx);
        % interpolate
        GapData = DataPre(end) + (1:GapLen)/(GapLen+1) * (DataPost(1)-DataPre(end));
        obj.RAEEGAcq(GapIdx) = GapData;

      end
    end

    % Calculate the average artifact
    %
    % Note: This must be performed for the upsampled data because it
    % internally relies on obj.TriggersUp and other sample-position
    % variables which are related to the upsampled data.
    %
    % in:  RAEEGAcq, RANoiseAcq
    % out: RAEEGAcq, RANoiseAcq
    function RACalcAvgArt(obj,Channel)
      AvgArt = obj.CalcAvgArt(Channel);
      obj.RAEEGAcq   = obj.RAEEGAcq   - AvgArt;
      obj.RANoiseAcq = obj.RANoiseAcq + AvgArt;
    end

    % PCA of residuals
    %
    % in:  RAEEGAcq, RANoiseAcq
    % out: RAEEGAcq, RANoiseAcq
    function RAPCA(obj,Channel)
      if isempty(intersect(obj.OBSExcludeChannels,Channel)) & (obj.OBSNumPCs~=0)
        Ipca = filtfilt(obj.OBSHPFilterWeights,1,obj.RAEEGAcq);
        papc = obj.DoPCA(Ipca);
        fitted_res = obj.FitOBS(Ipca,papc);
      elseif ~obj.SliceTrigger % not doing OBS and using volume triggers
        Ipca = obj.RAEEGAcq;
        papc = double(ones(PrePeak+max_postpeak+1,1));   % column-vector with all '1'
        fitted_res = obj.FitOBS(Ipca,papc);
        % TODO: this seems to calculate the mean of every Ipca section
      else
        fitted_res=zeros(length(obj.RANoiseAcq),1);
      end
      % fitted_res now holds a column vector with residuals

      % subtract noise
      obj.RANoiseAcq=obj.RANoiseAcq+fitted_res';
      obj.RAEEGAcq  =obj.RAEEGAcq  -fitted_res';
    end

    % Down sampling
    %
    % in:  RAEEGAcq, RANoiseAcq
    % out: RAEEGAcq, RANoiseAcq
    function RADownSample(obj)
      if obj.Upsample > 1
        obj.RAEEGAcq  =FACET.decimate(obj.RAEEGAcq,  obj.Upsample);
        obj.RANoiseAcq=FACET.decimate(obj.RANoiseAcq,obj.Upsample);
      end
    end

    % Low-pass filter EEG and noise data
    %
    % in:  RAEEGAll, RANoiseAll
    % out: RAEEGAll, RANoiseAll
    function RALowPass(obj)
      if obj.FinalLPFrequency>0
        obj.RAEEGAll  =filtfilt(obj.FinalLPFilterWeights,1,obj.RAEEGAll);
        obj.RANoiseAll=filtfilt(obj.FinalLPFilterWeights,1,obj.RANoiseAll);
      end
    end

    % Adaptive Noise cancellation
    %
    % in:  RAEEGAll, RANoiseAll
    % out: RAEEGAll, RANoiseAll
    function RAANC(obj)
      if obj.DoANC
        obj.RAEEGAll = obj.AdaptiveNoiseCancellation(obj.RAEEGAll,obj.RANoiseAll);
      end
    end

    % 
    function ProfileStart(obj)
      if ~obj.Profiling
        return
      end
      % append start time
      obj.ProfilingStarts(end+1) = tic;
    end

    function ProfileStop(obj,varargin)
      if ~obj.Profiling
        return
      end
      % calculate stop time
      elapsed = toc(obj.ProfilingStarts(end));
      % remove last element
      obj.ProfilingStarts = obj.ProfilingStarts(1:(end-1));
      % show elapsed time
      if nargin == 2
        fprintf('  %s: %s\n',varargin{1},FACET.SecToString(elapsed));
      else
        fprintf('  %s\n',FACET.SecToString(elapsed));
      end
    end

    function [amin,amax] = FindAcquisition(obj)
      n=1000;                  % number of samples to summarize
      c=0.1;                   % part between min and max summary
      l=obj.NumSamples;
      lu=n*ceil(l/n);          % round up to next 1000
      ld=lu-l;                 % addition to next 1000
      lq=lu/n;                 % number of 1000s
      d=sum(obj.FEEG.data,1);  % sum along channel index
      d=[d zeros(1,ld)];       % complete to length dividable by 1000 
      e=reshape(d,n,lq);       % make chunks of 1000
      r=max(e);                % maximum height in each interval
      mi=min(r);
      ma=max(r);
      mc=mi+(ma-mi)*c;         % cutoff range is at 10% between min and max maxima
      f=find(d>mc);
      amin = f(1);
      amax = f(end);
    end

  end

  methods(Static)

    % Reconstruct missing Triggers
    % 
    %
    % Test with Niazy EEG-fMRI test data (40 volumes, 21 slices):
    %   % remove some triggers
    %   TrigsNew=setdiff(Trigs,Trigs([132,140,252,387,770]+1));
    %   % reconstruct
    %   TrigsNewAll=FACET.FACET.CompleteTriggers(TrigsNew,40,21);
    %   % evaluate
    %   TrigsNewAllDiff=diff(TrigsNewAll);
    %   stem(TrigsNewAllDiff);   % looks like before
    %   d=TrigsNewAll-Trigs;     % difference to before
    %   stem(d)                  % a single error with an offset of 1 (i.e. very low)
    %
    % Show histogram of distances
    %   [N,X]=hist(TrigsDiff,min(TrigsDiff):max(TrigsDiff));
    %   stem(X(find(N)),N(find(N)));
    function AllTrigs = CompleteTriggers(Trigs,Volumes,Slices)
      TrigsNum  = length(Trigs);
      TrigsDiff = diff(Trigs);   % [ T2-T1  T3-T2  T4-T3 ... ]

      CorrectTrigsNum = Volumes*Slices;

      ErrNum = CorrectTrigsNum - TrigsNum;

      VolumesPerSection = 5;
      TrigsPerSection   = VolumesPerSection * Slices;
      Sections = floor(length(TrigsDiff)/TrigsPerSection);

      % Sections-by-TrigsPerSection matrix
      TrigsDiffMat = reshape(TrigsDiff(1:Sections*TrigsPerSection),...
                       TrigsPerSection,Sections)';
      TrigsDiffMax = min(max(       TrigsDiffMat,[],2));  % maximum within section, minimum of all sections
      TrigsDiffMin = round(mean(min(TrigsDiffMat,[],2))); % minimum within section, mean of all sections
      TrigsDiffErr = max(max(       TrigsDiffMat,[],2));  % maximum distance

      ErrThreshold = mean([TrigsDiffMin TrigsDiffErr]);

      ErrIndices = find(TrigsDiff > ErrThreshold);

      % Check that we found exactly the number of missing triggers
      if ErrNum ~= length(ErrIndices)
        error('FACET:CorrectTriggers:CantFindTrigs','Can not determine trigger errors. There are %d triggers missing but we found %d.',ErrNum,length(ErrIndices));
      end

      % Determine volume triggers as those with the maximum difference. We
      % assume that there is a short break between every volume.
      VolumeTrigs = find(TrigsDiff >= (TrigsDiffMax-2) & TrigsDiff <= (TrigsDiffMax+2));

      % Calculate positions of missing triggers
      for ErrIndex = ErrIndices
        PostVolumeIndex = find((VolumeTrigs - ErrIndex) > 0,1);
        if (VolumeTrigs(PostVolumeIndex) - VolumeTrigs(PostVolumeIndex-1)) > Slices
          TriggerInterval = TrigsDiffMax;   % last slice trigger -> first slice trigger
        else
          TriggerInterval = TrigsDiffMin;   % between slice triggers
        end
        % append position to trigger list
        Trigs(end+1) = Trigs(ErrIndex) + TriggerInterval;
      end

      % use new trigger positions
      AllTrigs = sort(Trigs);
    end

  end

end

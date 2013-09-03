%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EVAL  Characterize algorithm with several criteria
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
classdef Eval < handle
  % EVAL  Characterize algorithm with several criteria
  %   The output data of an EEG-fMRI artifact removal algorithm is
  %   characterized with several criteria. The results are stored in the
  %   result property in an EvalResult object. Use EvalPrint descendants
  %   to print the result to the screen or other formats.
  %
  % Usage (see constructor below):
  %   obj = FACET.Eval(EEG_orig,EEG_corr,EEG_Channels,SlicesPerVolume,EventType,TriggerOffset);
  %   obj = FACET.Eval(EEG_orig,FACET);
  %   obj.eval()
  %   p = FACET.EvalPrintText(obj.result);
  %   p.print();
  %
  % or in one line
  %   eval=FACET.EvalPrintText(FACET.Eval(EEG_FMRIB,eegfmri_r141,[1:30],21).eval()).print();
  %
  % You can customize the algorithm by setting the public properties. For
  % details please refer to their descriptions below.
  %
  % Note: This class also works with only a single entry in EEG_Channels.
  % In this case there is no variability in the results for the individual
  % characteristics. Therefore the min/max/mean/median descriptives are
  % all identical.
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Classes
  % -------
  %   Eval             Evaluation of an artifact removal algorithm
  %   EvalResult       Result storage container
  %   EvalPrint        Abstract base class to print the result
  %   EvalPrintText    Implements print() to print a nice human-readable table
  %
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % Design
  % ------
  % This class implements the evaluation of the results of an algorithm to
  % remove fMRI results from an EEG signal. It implements 6 different
  % criterions, which all are implemented as private methods.
  %
  % The results are stored to the read-only property "result", which is an
  % EvalResult object.
  %

  % public properties
  properties(Access=public)
    %%% Evaluation Setup
    % Channels which should be used for evaluation
    EEG_Channels = [];
    % Specify whether triggers are used or not to get information on the
    % fMRI acquisition onset and the volume and slice frequency.
    UseTriggers;
    %%% Use Case 1: use triggers as information
    % fMRI slices per volume
    SlicesPerVolume = [];
    % Type of trigger event. All events which event.type matches EventType
    % are used. If left unset, all events are used.
    % To get a list of all event types try
    %   unique({EEG.event.type})
    EventType = [];
    % Offset of trigger times. The value of this variable is added to the
    % values taken from event.latency. If the trigger events from the
    % original data set are too late, you have to put a negative number
    % here.
    TriggerOffset = 0;
    %%% Use Case 2: don't use triggers as information
    % Sample index safely before and after fMRI acquitistion onset and end.
    % In use case 1 the values of the Acq* properties are automatically
    % calculated from the triggers as specified by EventType above. If you
    % set all four values, these will be used instead. In use case 2 you
    % have to set all four values on your own.
    AcqPreStart;
    AcqPostStart;
    AcqPreEnd;
    AcqPostEnd;
    % fMRI volume and slice frequencies
    VolumeFrequency;
    SliceFrequency;
    % high-pass to remove low-frequency baseline wandering
    HPf     = 1.0;    % Hz
    % HP is performed with FFT, so no firls() parameters necessary
    % low-pass to filter EEG_without to be equally treated as the
    % corrected signal (see FinalLP before ANC).
    LPf        = 70.0;  % Hz
    LPminorder = 15;    % minimum filter order
    LPminfac   = 3;     % factor for filter order
    LPtrans    = 0.15;  % transition, + nyquist frequency

    %%% Configuration of some evaluation algorithms
    % bounds of frequency bands for fft_allen
    fft_allen_band_bounds = [0.8,4,8,12,24];   % in Hz
  end

  % read-only properties
  properties(GetAccess=public,SetAccess=protected)
    % low-pass for signal outside of corrected times
    LPwght = [];
    % result struct, is an EvalResult object
    result = [];
  end

  % private properties
  properties(Access=protected)
    % EEG directly from amplifier (EEGLAB structure)
    EEG_orig;
    % EEG after correction (EEGLAB structure)
    EEG_corr;
    % preparation status
    prepared = false;
    % EEG triggers
    Triggers;
    % EEG sections, cut out from the full data and filtered
    EEG_original  = [];
    EEG_corrected = [];
    EEG_without   = [];
  end

  methods(Access=public)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constuctor
    %
    % Usage: E = Eval(EEG_orig,EEG_corr.SlicesPerVolume);
    %   EEG_orig          original EEG from amplifier, EEGLAB structure
    %   EEG_corr          an FACET object after performed correction
    %   SlicesPerVolume   slices per volume during fMRI acquisition
    %
    % Usage: E = Eval(EEG_orig,EEG_corr,EEG_Channels,SlicesPerVolume,EventType,TriggerOffset);
    %   EEG_corr          EEG after correction, EEGLAB structure
    %   EEG_Channels      Channels which should be used for evaluation. If
    %                     empty ([]), all channels will be used.
    %   EventType         Type of trigger event in EEGLAB structure
    %                     Triggers must be slice trigger.
    %                     (optional, if left unset, all events are used)
    %   TriggerOffset     Offset of trigger times, added to the trigger
    %                     event latencies given in the EEGLAB structures
    %                     (optional, using 0 if unset)
    %
    % Usage: E = Eval(EEG_orig,EEG_corr,EEG_Channels,AcqPreStart,AcqPostStart,AcqPreEnd,AcqPostEnd,VolumeFrequency,SliceFrequency);
    %   Acq*              Sample instances safely before and after fMRI
    %                     acquisition onset and end (optional, set all 4)
    %   VolumeFrequency   volume frequency
    %   SliceFrequency    slice frequency
    function obj=Eval(EEG_orig,EEG_corr,varargin)
      % create object for evaluation results
      obj.result = FACET.EvalResult();
      
      if nargin == 3
        % Usage with FACET object
        obj.EEG_orig        = EEG_orig;
        obj.EEG_corr        = EEG_corr.EEG;
        obj.EEG_Channels    = setdiff(1:EEG_corr.NumChannels,EEG_corr.ExcludeChannels);
        obj.SlicesPerVolume = varargin{1};
        obj.EventType       = EEG_corr.EventType;
        obj.TriggerOffset   = EEG_corr.TriggerOffset;
        obj.LPwght          = EEG_corr.FinalLPFilterWeights;
        obj.UseTriggers     = true;
      else
        % Usage with two EEGLAB structures plus more information
        obj.EEG_orig        = EEG_orig;
        obj.EEG_corr        = EEG_corr;
        obj.EEG_Channels    = varargin{1};
        if isempty(obj.EEG_Channels)
          obj.EEG_Channels = 1:size(EEG_orig,1);
        end
        if (nargin >= 4) && (nargin <= 6)
          % Use Case 1: use triggers for information
          obj.UseTriggers     = true;
          obj.SlicesPerVolume = varargin{2};
          if nargin >= 5
            obj.EventType       = varargin{3};
          end
          if nargin == 6
            obj.TriggerOffset   = varargin{4};
          end
        elseif nargin == 9
          % Use Case 2: don't use triggers for information
          obj.UseTriggers     = false;
          obj.AcqPreStart     = varargin{2};
          obj.AcqPostStart    = varargin{3};
          obj.AcqPreEnd       = varargin{4};
          obj.AcqPostEnd      = varargin{5};
          obj.VolumeFrequency = varargin{6};
          obj.SliceFrequency  = varargin{7};
        else
          error('Eval:WrongArguments','Wrong number of arguments');
        end
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % perform the evaluation
    function result = eval(obj)
      % prepare all data
      obj.prepare();

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Amplitude %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % amp_median: median of peak-peak voltage values

      % calculate length for our "measurements"
      if obj.UseTriggers
        % maximum event distances + 10%
        MLen = round(max(diff(obj.Triggers))*1.10);
      else
        % slice time + 20%
        MLen = round(1.20 * obj.EEG_orig.srate / obj.SliceFrequency);
      end
      % prepare data
      [without,corrected] = obj.allen_prepare(MLen);
      % calculate measures of corrected signal
      [VMin VMax VMed] = obj.amp_median(corrected);

      obj.result.pkpk.min    = VMin;
      obj.result.pkpk.max    = VMax;
      obj.result.pkpk.median = VMed;

      % calculate measures of signal without artifacts
      [VMin VMax VMed] = obj.amp_median(without);

      obj.result.pkpk.wmin    = VMin;
      obj.result.pkpk.wmax    = VMax;
      obj.result.pkpk.wmedian = VMed;

      % ratio
      obj.result.pkpk.rmin    = obj.result.pkpk.min    / obj.result.pkpk.wmin;
      obj.result.pkpk.rmax    = obj.result.pkpk.max    / obj.result.pkpk.wmax;
      obj.result.pkpk.rmedian = obj.result.pkpk.median / obj.result.pkpk.wmedian;

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % RMS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % rms_residual: Ratio between RMS of corrected signal to RMS of signal
      %   without artifacts

      % analyze data
      r = obj.rms_residual();
      % store results
      obj.result.rms_residual.data   = r;
      obj.result.rms_residual.min    = min   (r,[],1);
      obj.result.rms_residual.max    = max   (r,[],1);
      obj.result.rms_residual.mean   = mean  (r,   1);
      obj.result.rms_residual.median = median(r,   1);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % rms_correction: Ratio between RMS of uncorrected signal to RMS of
      %   corrected signal

      % analyze data
      r = obj.rms_correction();
      % store results
      obj.result.rms_correction.data   = r;
      obj.result.rms_correction.min    = min   (r,[],1);
      obj.result.rms_correction.max    = max   (r,[],1);
      obj.result.rms_correction.mean   = mean  (r,   1);
      obj.result.rms_correction.median = median(r,   1);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % SNR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % snr_residual: SNR of EEG without aftifacts to corrected EEG

      % reuse EEG_corrected and EEG_without from rms_residual
      r = obj.snr_residual();
      % store results
      obj.result.snr_residual.data   = r;
      % remove negative SNR values
      r=r(r>=0);
      % store statistics
      obj.result.snr_residual.min    = min   (r,[],1);
      obj.result.snr_residual.max    = max   (r,[],1);
      obj.result.snr_residual.mean   = mean  (r,   1);
      obj.result.snr_residual.median = median(r,   1);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % snr_surrogate: Calculate SNR from correlation between surrogate sine
      %   signal and the residuals still there after application of the
      %   algorithm.

      % Not used here

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % FFT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % fft_allen: Calculate median of differences between samples without
      % acquisition and with corrected EEG in four frequency bands. The values
      % are percent absolute difference of corrected to non-acquisition, so
      % the lower the better.

      % prepare the data
      % use 3 sec. periods (instead of 5.12s = 1024 samples at 200Sps)
      [NSections,CSections] = obj.allen_prepare(obj.EEG_corr.srate*3);
      % [NC]Sections are matrices with: Sample x Measurement x Channel
      % but fft_allen expects           Channel x Measurement x Sample
      NSections=permute(NSections,[3 2 1]);
      CSections=permute(CSections,[3 2 1]);
      % analyze data
      r = obj.fft_allen(NSections,CSections,obj.EEG_corr.srate);
      % store results
      obj.result.fft_allen.freqs   = obj.fft_allen_band_bounds;
      obj.result.fft_allen.medians = r;

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % fft_niazy: Calculate ratio of spectral power between uncorrected and
      % corrected EEG at volume frequency and harmonics.

      % analyze data
      [rv,rs] = obj.fft_niazy(obj.VolumeFrequency,obj.SliceFrequency);
      % rv and rs are 
      % store results
      obj.result.fft_niazy.vratios = rv;
      obj.result.fft_niazy.vfreqs  = obj.VolumeFrequency*(1:size(rv,2));
      rv = 10 * log10(rv);   % calculate dB
      obj.result.fft_niazy.vmin    = min   (rv,[],1);   % minimum across channels
      obj.result.fft_niazy.vmax    = max   (rv,[],1);   % maximum across channels
      obj.result.fft_niazy.vmean   = mean  (rv,   1);   % mean    across channels
      obj.result.fft_niazy.vmedian = median(rv,   1);   % median  across channels
      obj.result.fft_niazy.sratios = rs;
      obj.result.fft_niazy.sfreqs  = obj.SliceFrequency*(1:size(rs,2));
      rs = 10 * log10(rs);   % calculate dB
      obj.result.fft_niazy.smin    = min   (rs,[],1);   % minimum across channels
      obj.result.fft_niazy.smax    = max   (rs,[],1);   % maximum across channels
      obj.result.fft_niazy.smean   = mean  (rs,   1);   % mean    across channels
      obj.result.fft_niazy.smedian = median(rs,   1);   % median  across channels

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % fft_vandermeer: Calculate and show the spectrogram of two EEG records

      % Not used here

      % return object for nice command line calling
      result = obj.result;
    end

  end

  methods(Access=protected)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Prepare EEG data commonly used by several evaluation functions
    %
    % This function doesn't do anything new if called multiple times.
    function prepare(obj)
      if obj.prepared
        return
      end

      %%% Prepare filters
      % low-pass to filter EEG_without to be equally treated as the
      % corrected signal (see FinalLP before ANC).
      if isempty(obj.LPwght)
        nyq=obj.EEG_corr.srate/2;
        filtorder=max(obj.LPminorder,round(obj.LPminfac*fix(obj.EEG_corr.srate/obj.LPf)));
        if rem(filtorder,2)~=0       % ensure filtorder is even
            filtorder=filtorder+1;
        end
        f=[0 obj.LPf/nyq obj.LPf*(1+obj.LPtrans)/nyq 1];
        a=[1 1 0 0];
        obj.LPwght=firls(filtorder,f,a);
      end

      %%% Prepare EEG data
      % EEG.data: 32x332416

      % get information from triggers
      if obj.UseTriggers
        obj.Triggers = FACET.FindTriggers(obj.EEG_corr.event,obj.EventType,obj.TriggerOffset);
        % calculate volume frequency
        d=obj.Triggers(1+obj.SlicesPerVolume:end) - obj.Triggers(1:end-obj.SlicesPerVolume);  % trigger distances between 1 volume
        obj.VolumeFrequency = obj.EEG_corr.srate / median(d);  % volume frequency
        % calculate slice frequency
        d=obj.Triggers(1+1:end) - obj.Triggers(1:end-1);   % trigger distances between 1 slice
        obj.SliceFrequency = obj.EEG_corr.srate / mean(d);  % slice frequency, yes it is the mean _including_ the irregular delays at volume borders
      end
      % calculate onset/end of acquisition
      if isempty(obj.AcqPreStart)
        if ~obj.UseTriggers
          error('Eval:AcqDataMissing','You chose to not use triggers as information but didn''t specify Acq*');
        end
        % calculate fMRI acquisition start/end sample indices
        l1 = obj.Triggers(1);
        l2 = obj.Triggers(2);
        ln = obj.Triggers(end-1);
        ll = obj.Triggers(end);
        dl = l2-l1;   % distance between two triggers
        % Acquisition start and end
        obj.AcqPreStart  = l1-2*dl;
        obj.AcqPostStart = l2;
        obj.AcqPreEnd    = ln;
        obj.AcqPostEnd   = ll+2*dl;
      end
      % prepare signal sections with/without acquisition
      % use signal between 2nd and one-before-last trigger
      obj.EEG_original  = obj.EEG_orig.data(obj.EEG_Channels,obj.AcqPostStart:obj.AcqPreEnd);
      obj.EEG_corrected = obj.EEG_corr.data(obj.EEG_Channels,obj.AcqPostStart:obj.AcqPreEnd);
      % use signal before and after triggers
      obj.EEG_without   = [ obj.EEG_orig.data(obj.EEG_Channels,1:obj.AcqPreStart),...
                            obj.EEG_orig.data(obj.EEG_Channels,obj.AcqPostEnd:end) ];
      % apply filter
      obj.EEG_original  = FACET.fftgausshp(obj.EEG_original', obj.HPf,obj.EEG_corr.srate)';
      obj.EEG_corrected = FACET.fftgausshp(obj.EEG_corrected',obj.HPf,obj.EEG_corr.srate)';
      obj.EEG_without   = FACET.fftgausshp(obj.EEG_without',  obj.HPf,obj.EEG_corr.srate);
      obj.EEG_without   = filtfilt(obj.LPwght,1,obj.EEG_without)';
      % TODO: ensure that there are no filter start/end effects

      % Show raw data characteristics
%      obj.print_raw_info('EEG_original');
%      obj.print_raw_info('EEG_corrected');
%      obj.print_raw_info('EEG_without');
%      obj.plot_fft();

      % store that everything is prepared
      obj.prepared = true;
    end

    function print_raw_info(obj,name)
      fprintf('%s:\n',name);
      x=range(obj.(name),2);
      fprintf(' - range: %10.2f - %10.2f\n',min(x), max(x));
      x=mean(obj.(name),2);
      fprintf(' - mean:  %10.2f - %10.2f    E-6\n',min(x)*1000000, max(x)*1000000);
      x=std(obj.(name),[],2);
      fprintf(' - std:   %10.2f - %10.2f\n',min(x), max(x));
    end

    function plot_fft(obj)
      fft_without   = fft(obj.EEG_without,  [],2);
      fft_original  = fft(obj.EEG_original, [],2);
      fft_corrected = fft(obj.EEG_corrected,[],2);
      d=abs(fft_original)-abs(fft_corrected);

      lw=size(fft_without,2);
      fw=(0:(lw-1))/lw*obj.EEG_orig.srate;
      l=size(fft_original,2);
      f=(0:(l-1))/l*obj.EEG_orig.srate;

      semilogy(f,abs(fft_original(1,:)));
      hold on
      semilogy(f,abs(fft_corrected(1,:)),'r');
      semilogy(fw,abs(fft_without(1,:)),'b');
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Prepare EEG data used by amp_median and fft_allen
    function [without,corrected] = allen_prepare(obj,MLen)
      % number of measururements
      MNum = 10;
      % distance between these MNum measurements
      MDist = floor((size(obj.EEG_corrected,2) - MLen) / (MNum-1));
      % MNum = 3, MLen = 3, size(...)= 8 -> ( 8-3)/(3-1) = 5/2 = 2.66 -> ... floor(2*2.66)+1=6
      % MNum = 3, MLen = 3, size(...)= 9 -> ( 9-3)/(3-1) = 6/2 = 3.00 -> 0*3+1, 1*3+1, 
      % MNum = 3, MLen = 3, size(...)=10 -> (10-3)/(3-1) = 7/2 = 3.33 -> floor(2*3.33)+1=7, should be 8, but we stay at the save side
      if MDist < MLen
        warning('amp_median_prepare:OverlappingCorr','Sections of corrected samples overlap (dist %d < len %d)',MDist,MLen);
      end
      % start indices of measurements
      MStart = floor((0:(MNum-1))*MDist) + 1;
      % get 10 equally spaced measurements per channel
      corrected = zeros(MLen,MNum,length(obj.EEG_Channels));
      for Channel = 1:length(obj.EEG_Channels)
        for i = 1:MNum
          corrected(:,i,Channel) = obj.EEG_corrected(Channel,MStart(i):(MStart(i)+MLen-1));
        end
      end

      %%% prepare data without acquisition
      % distenace between these MNum measurements
      MDist = floor((size(obj.EEG_without,2) - MLen) / (MNum-1));
      if MDist < MLen
        warning('amp_median_prepare:OverlappingCorr','Sections of non-degraded samples overlap (dist %d < len %d)',MDist,MLen);
      end
      % start indices of measurements
      MStart = floor((0:(MNum-1))*MDist) + 1;
      % get 10 equally spaced measurements per channel
      without = zeros(MLen,MNum,length(obj.EEG_Channels));
      for Channel = 1:length(obj.EEG_Channels)
        for i = 1:MNum
          without(:,i,Channel) = obj.EEG_without(Channel,MStart(i):(MStart(i)+MLen-1));
        end
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % methods defined in their own files
    [VMin VMax VMed] = amp_median(obj,Samples);
    ratio = rms_residual(obj);
    ratio = rms_correction(obj);
    snr = snr_residual(obj);
    m_pd = fft_allen(obj,sections_n,sections_c,srate);
  end

end

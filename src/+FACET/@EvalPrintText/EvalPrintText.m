%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EVALPRINTTEXT  Pretty-print an EvalResult object for humans
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
classdef EvalPrintText < FACET.EvalPrint

  methods(Access=public)

    function obj=EvalPrintText(EvalResultOrContainer)
      % call constructor of super-class
      obj = obj@FACET.EvalPrint(EvalResultOrContainer);
    end

    % Pretty-print the evaluation result
    %
    % fid ... (optional) File identifier from fopen(), if omitted, the
    %         result is printed to stdout 
    function result = print(obj,fid)
      % check EvalResultContainer list
      if isempty(obj.Container)
        error('EvalPrintText:NoData','You have to add at least one EvalResult object before you print it.');
      end
      % always use first result
      if length(obj.Container) > 1
        warning('EvalPrintText:MultiData','EvalPrintText only prints the first EvalResult, but you have added a total of %d',length(obj.Container));
      end
      EvalResult = obj.Container(1).EvalResult;
      % file descriptor
      if nargin == 1
        fid = 1;  % default to stdout
      end
      % pretty-print
      obj.PrintOne(fid,EvalResult);
      % Return EvalResult for a convenient one-line command line
      result = EvalResult;
    end

  end

  methods(Static,Access=protected)

    % Pretty-print
    function PrintOne(fid,EvalResult)
      fprintf(fid,'Amplitude ################################################################\n');
      fprintf(fid,'  amp_median: Peak-peak voltage values (the nearer to EEG/EMG values the\n');
      fprintf(fid,'  better):\n');
      fprintf(fid,'               corrected       without          corr/without\n');
      fprintf(fid,'    Min:    %10.4f      %10.4f      %10.4f\n',EvalResult.pkpk.min,   EvalResult.pkpk.wmin,   EvalResult.pkpk.rmin);
      fprintf(fid,'    Max:    %10.4f      %10.4f      %10.4f\n',EvalResult.pkpk.max,   EvalResult.pkpk.wmax,   EvalResult.pkpk.rmax);
      fprintf(fid,'    Median: %10.4f      %10.4f      %10.4f\n',EvalResult.pkpk.median,EvalResult.pkpk.wmedian,EvalResult.pkpk.rmedian);
      fprintf(fid,'RMS ######################################################################\n');
      fprintf(fid,'  rms_residual: Ratio between RMS of corrected to unimpaired signal (the\n');
      fprintf(fid,'  nearer to 1.0 the better):\n');
      fprintf(fid,'    Min:    %10.4f\n',EvalResult.rms_residual.min);
      fprintf(fid,'    Max:    %10.4f\n',EvalResult.rms_residual.max);
      fprintf(fid,'    Mean:   %10.4f\n',EvalResult.rms_residual.mean);
      fprintf(fid,'    Median: %10.4f\n',EvalResult.rms_residual.median);
      fprintf(fid,'  rms_correction: Ratio between RMS of uncorrected signal to RMS of\n');
      fprintf(fid,'  corrected signal (the larger the better):\n');
      fprintf(fid,'    Min:    %10.4f\n',EvalResult.rms_correction.min);
      fprintf(fid,'    Max:    %10.4f\n',EvalResult.rms_correction.max);
      fprintf(fid,'    Mean:   %10.4f\n',EvalResult.rms_correction.mean);
      fprintf(fid,'    Median: %10.4f\n',EvalResult.rms_correction.median);
      fprintf(fid,'SNR ######################################################################\n');
      fprintf(fid,'  snr_residual: SNR of EEG without aftifacts to corrected EEG (the larger\n');
      fprintf(fid,'  the better):\n');
      fprintf(fid,'    SNR>=0: %10d\n',  sum(EvalResult.snr_residual.data>=0));
      fprintf(fid,'    Min:    %10.4f\n',EvalResult.snr_residual.min);
      fprintf(fid,'    Max:    %10.4f\n',EvalResult.snr_residual.max);
      fprintf(fid,'    Mean:   %10.4f\n',EvalResult.snr_residual.mean);
      fprintf(fid,'    Median: %10.4f\n',EvalResult.snr_residual.median);
      fprintf(fid,'FFT ######################################################################\n');
      fprintf(fid,'  fft_allen: Calculate median of differences between samples without\n');
      fprintf(fid,'  acquisition and with corrected EEG in four frequency bands. (the lower\n');
      fprintf(fid,'  the better):\n');
      for i = 1:length(EvalResult.fft_allen.medians)
        fprintf(fid,'    %4.1f - %4.1f Hz:   %10.4f %%\n',...
          EvalResult.fft_allen.freqs(i),...
          EvalResult.fft_allen.freqs(i+1),...
          EvalResult.fft_allen.medians(i));
      end
      fprintf(fid,'  fft_niazy: Calculate ratio of spectral power between uncorrected and\n');
      fprintf(fid,'  corrected EEG at volume and slice frequency and harmonics (the smaller the\n');
      fprintf(fid,'  better):\n');
      fprintf(fid,'  Volume:               min         max        mean      median\n');
      for i = 1:size(EvalResult.fft_niazy.vratios,2)
        fprintf(fid,'    %d %6.3fHz:  %8.2fdB  %8.2fdB  %8.2fdB  %8.2fdB\n',...
          i,...
          EvalResult.fft_niazy.vfreqs (i),...
          EvalResult.fft_niazy.vmin   (i),...
          EvalResult.fft_niazy.vmax   (i),...
          EvalResult.fft_niazy.vmean  (i),...
          EvalResult.fft_niazy.vmedian(i));
      end
      fprintf(fid,'  Slice:                min         max        mean      median\n');
      for i = 1:size(EvalResult.fft_niazy.sratios,2)
        fprintf(fid,'    %d %6.2fHz:  %8.2fdB  %8.2fdB  %8.2fdB  %8.2fdB\n',...
          i,...
          EvalResult.fft_niazy.sfreqs (i),...
          EvalResult.fft_niazy.smin   (i),...
          EvalResult.fft_niazy.smax   (i),...
          EvalResult.fft_niazy.smean  (i),...
          EvalResult.fft_niazy.smedian(i));
      end
    end

  end

end

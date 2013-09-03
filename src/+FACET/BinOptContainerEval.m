%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Data storage container for BinOptRunCleanEx5 and others
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef BinOptContainerEval < FACET.BinOptContainer

  methods(Access=public)

    % Constructor
    function obj = BinOptContainerEval(Options)
      % call constructor of super-class
      obj = obj@FACET.BinOptContainer(Options);
    end

    % Get the Median of the Pk-Pk values (amp_allen)
    function Result = GetPkPkMedian(obj,Index)
      Func = @(Data) Data.Eval.pkpk.median;   % anonymous function
      Result = obj.GetFunc(Index,Func);
    end

    % Get the RMS Corrected to Unimpaired (rms_residual)
    function Result = GetRMSResidual(obj,Index)
      Func = @(Data) Data.Eval.rms_residual.mean;   % anonymous function
      Result = obj.GetFunc(Index,Func);
    end

    % Get the RMS Uncorrected to Corrected (rms_correction)
    function Result = GetRMSCorrection(obj,Index)
      Func = @(Data) Data.Eval.rms_correction.mean;   % anonymous function
      Result = obj.GetFunc(Index,Func);
    end

    % Get the SNR of Corrected (snr_residual)
    function Result = GetSNRResidual(obj,Index)
      Func = @(Data) Data.Eval.snr_residual.mean;   % anonymous function
      Result = obj.GetFunc(Index,Func);
    end

    % Get the Median Residual Activity
    function Result = GetFFTAllen(obj,Index)
      Func = @(Data) Data.Eval.fft_allen.medians;   % anonymous function
      Result = obj.GetFunc(Index,Func);
    end

    % Get the Power Density Reduction at volume harmonics
    function Result = GetFFTNiazyVolume(obj,Index)
      Func = @(Data) Data.Eval.fft_niazy.vmean;   % anonymous function
      Result = obj.GetFunc(Index,Func);
    end

    % Get the Power Density Reduction at slice harmonics
    function Result = GetFFTNiazySlice(obj,Index)
      Func = @(Data) Data.Eval.fft_niazy.smean;   % anonymous function
      Result = obj.GetFunc(Index,Func);
    end

    % Add EvalResult objects to an EvalPrint object
    %
    % EP: the EvalPrint class
    %
    % Which (optional): an array with run indices, as supplied to Get(),
    %   if it is not supplied, all runs from 0 to NumRuns-1 will be used
    %
    % ShortTitles (optional): short titles for the (selected) runs,
    %   if it is not supplied, a comma separated list of the options of
    %   each run will be used
    %
    function FillEvalPrint(obj,EP,varargin)
      Which = 0:(obj.NumRuns-1);
      if nargin >= 3
        Which = varargin{1};
        if (min(Which(:)) < 0) || (max(Which(:)) >= obj.NumRuns)
          error('FACET:BinOptContainerEval:FillEvalPrint:InvalidIndex','Invalid index argument, must be between 0 and %d',obj.NumRuns-1);
        end
      end
      ShortTitles = obj.GetOptions(Which);
      if nargin == 4
        ShortTitles = varargin{2};
        if length(ShortTitles) ~= length(Which)
          error('FACET:BinOptContainerEval:FillEvalPrint:ShortTitlesLength','ShortTitles must have the same number of elements as Which (%d)',length(Which));
        end
      end

      for i = 1:length(Which)
        Index      = Which(i);
        ShortTitle = ShortTitles{i};
        if iscell(ShortTitle)
          ShortTitle = FACET.StrJoinCell(', ',ShortTitle);
        end
        EP.AddResult(FACET.EvalResultContainer(obj.Get(Index).Eval,ShortTitle));
      end
    end

  end

  methods(Access=protected,Static)

    % Create one BinOptDataEval object
    function Data = CreateData()
      Data = FACET.BinOptDataEval();
    end

  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EVALRESULT  Result storage for Eval
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
classdef EvalResult < handle

  properties(Access=public)
    % Result from amp_median
    % Note: It is not necessary to initialize this property, because all
    % assignments (as a struct) work without initialization.
    pkpk = struct(...
      'min',     [], ...   % corrected EEG
      'max',     [], ...
      'median',  [], ...
      'wmin',    [], ...   % EEG without artifacts
      'wmax',    [], ...
      'wmedian', [], ...
      'rmin',    [], ...   % ratio
      'rmax',    [], ...
      'rmedian', []  ...
    );
    % Results from rms_residual
    rms_residual = struct(...
      'data',    [], ...
      'min',     [], ...
      'max',     [], ...
      'mean',    [], ...
      'median',  []  ...
    );
    % Results from rms_correction
    rms_correction = struct(...
      'data',    [], ...
      'min',     [], ...
      'max',     [], ...
      'mean',    [], ...
      'median',  []  ...
    );
    % Results from snr_residual
    snr_residual = struct(...
      'data',    [], ...
      'min',     [], ...
      'max',     [], ...
      'mean',    [], ...
      'median',  []  ...
    );
    % Results from fft_allen
    fft_allen = struct(...
      'freqs',   [], ...
      'medians', []  ...
    );
    % Results from fft_niazy
    fft_niazy = struct(...
      'vfreqs',  [], ...    % volume frequency points
      'vratios', [], ...    % volume frequency ratios
      'vmin',    [], ...    % minimum across channels (in dB)
      'vmax',    [], ...    % maximum across channels
      'vmean',   [], ...    % mean    across channels
      'vmedian', [], ...    % median  across channels
      'sfreqs',  [], ...    % slice frequency points
      'sratios', [], ...    % slice frequency ratios
      'smin',    [], ...    % minimum across channels
      'smax',    [], ...    % maximum across channels
      'smean',   [], ...    % mean    across channels
      'smedian', []  ...    % median  across channels
    );
  end

  methods(Access=public)

    function obj=EvalResult()
      if nargin == 0
        % instantiate empty object
        % nothing to do
      elseif nargin == 1
        % instantiate object with data from old struct type result
        % TODO
      else
        error('EvalResult:WrongArguments','Wrong number of arguments');
      end
    end

  end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run CleanEx5 with combinations of binary options.
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
% This is the descendant of BinOptRun, which implements the actual
% function.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef BinOptRunCleanEx5 < FACET.BinOptRun

  properties(Access=public)
    % EEG input data for all runs
    EEG;
    % base options which will be added to the options which are permuted
    BaseOptions;
  end

  methods(Access=public)

    % Constructor
    %
    % Instanciate the (inherited) Container object and store the
    % EEG input data.
    function obj=BinOptRunCleanEx5(Options,EEG,BaseOptions)
      obj.Container   = FACET.BinOptContainerEval(Options);
      obj.EEG         = EEG;
      obj.BaseOptions = BaseOptions;
    end

  end

  methods(Access=protected)

    % Actual function
    %
    % This implements the abstract method of the base class.
    function RunOne(obj,Index,Options)
      % artifact removal algorithm
      rand('seed',0),
      Args = { obj.BaseOptions{:} Options{:} };
      obj.Container.Get(Index).EEG  = CleanEx5(obj.EEG,Args{:});
      % evaluation
      obj.Container.Get(Index).Eval = FACET.Eval(obj.EEG,obj.Container.Get(Index).EEG,[1:30],21).eval();
    end

  end

end

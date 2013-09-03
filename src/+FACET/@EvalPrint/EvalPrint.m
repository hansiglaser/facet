%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EVALPRINT  Abstract class to pretty-print an EvalResult object
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
% Inherit from this class and override the method print()
classdef EvalPrint < handle

  properties(GetAccess=public,SetAccess=protected)
    % Store an EvalResultContainer object
    Container = [];
  end

  methods(Access=public)

    % Constructor
    % Supply an EvalResult or an EvalResultContainer object
    function obj=EvalPrint(EvalResultOrContainer)
      if (nargin == 1) && ~isempty(EvalResultOrContainer)
        obj.AddResult(EvalResultOrContainer);
      end
    end

    % Add a result object
    % Supply an EvalResult or an EvalResultContainer object
    function AddResult(obj,EvalResultOrContainer)
      % check object type of argument
      if isa(EvalResultOrContainer,'FACET.EvalResultContainer') % including package name!
        % store local copy
        obj.Container = [obj.Container EvalResultOrContainer];
      elseif isa(EvalResultOrContainer,'FACET.EvalResult') % including package name!
        % got EvalResult, have to create our own EvalResultContainer
        obj.Container = [obj.Container FACET.EvalResultContainer(EvalResultOrContainer,'TODO:ShortTitle')];
      else
        error('EvalPrint:WrongClass','Wrong class type %s',class(EvalResultOrContainer));
      end
    end

  end

  methods(Abstract)

    % Pretty-print the EvalResult object
    %
    % fid ... (optional) File identifier from fopen(), if omitted, the
    %         result is printed to stdout 
    print(obj,fid);

  end

end

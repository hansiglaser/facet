%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EVALRESULTCONTAINER  Result description for EvalPrint
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
classdef EvalResultContainer < handle

  properties(GetAccess=public,SetAccess=protected)
    % EvalResult object
    EvalResult;
  end

  properties(Access=public)
    % Variable name used for the EvalResult object
    InputName;
    % Short title (e.g. for table header or diagram label)
    ShortTitle;
  end

  methods(Access=public)

    % Constructor
    function obj=EvalResultContainer(EvalResult,ShortTitle)
      % check object type of argument
      if ~isa(EvalResult,'FACET.EvalResult') % including package name!
        error('EvalResultContainer:WrongClass','Wrong class type %s, need FACET.EvalResult',class(EvalResult));
      end
      % store local copy
      obj.EvalResult = EvalResult;
      % store metainfo
      obj.InputName  = inputname(1);  % get variable name of function input
      obj.ShortTitle = ShortTitle;
    end

  end

end

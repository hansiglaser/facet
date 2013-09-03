%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Run a function with combinations of binary options.
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
% This is the base class which must be derived for an actual application.
%
% Wording: http://en.wiktionary.org/wiki/dichotomic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
classdef BinOptRun < handle

  properties(Access=public)
    % data storage, must be a BinOptContainer (descendant) instance
    Container;
  end

  methods(Access=public)

    % Constructor
    %
    % In the inherited class, you have to construct the Container as a
    % BinOptContainer (descendant)
    function obj=BinOptRun(Options)
    end

    % Interate over all options and execute the function
    %
    function Run(obj)
      for Index = 0 : obj.Container.NumRuns-1
        Options = obj.Container.GetOptions(Index);
        fprintf('###### Run %d of %d: %s ######\n',Index+1,obj.Container.NumRuns,FACET.StrJoinCell(', ',Options));
        obj.RunOne(Index,Options);
      end
    end

  end

  methods(Access=protected,Abstract)

    % Function with binary options to be executed
    %
    % This is an abstract method, which must be implemented by the
    % descendant class.
    RunOne(obj,Index,Options);

  end

end
